locals {
  # Your AWS EKS Cluster ID goes here.
  k8s_cluster_name = "EKSCluster"
}

# Create an EKS cluster
provider "kubernetes" {
  alias                  = "eks"
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks_cluster_auth.token
}


provider "helm" {
  alias = "eks"
  kubernetes {
    host                   = aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks_cluster_auth.token
  }
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = local.k8s_cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = [aws_subnet.wp_subnet_1.id, aws_subnet.wp_subnet_2.id]
  }
}

data "aws_eks_cluster" "target" {
  name = local.k8s_cluster_name

  depends_on = [aws_eks_cluster.eks_cluster]
}

# Create a Kubernetes configuration file
data "aws_eks_cluster_auth" "eks_cluster_auth" {
  name = aws_eks_cluster.eks_cluster.name

  depends_on = [aws_eks_cluster.eks_cluster]
}

# Create an IAM role for EKS cluster
resource "aws_iam_role" "eks_cluster" {
  name = "EKSClusterRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = ["eks.amazonaws.com", "ec2.amazonaws.com"]
      }
    }]
  })
}


# Attach policies to the IAM role for EKS cluster
resource "aws_iam_policy_attachment" "eks_cluster_policies" {
  name       = "EKSClusterPoliciesAttachment"
  roles      = [aws_iam_role.eks_cluster.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_policy_attachment" "eks_worker_node_policy_attachment" {
  name       = "EKSWorkerNodePolicyAttachment"
  roles      = [aws_iam_role.eks_cluster.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_policy_attachment" "ecr_readonly_policy_attachment" {
  name       = "ECRReadonlyPolicyAttachment"
  roles      = [aws_iam_role.eks_cluster.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_policy_attachment" "ssm_policy_attachment" {
  name       = "AmazonSSMManagedInstanceCoreAttachment"
  roles      = [aws_iam_role.eks_cluster.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy_attachment" "eks_cni_policy_attachment" {
  name       = "AmazonEKSCNIPolicyAttachment"
  roles      = [aws_iam_role.eks_cluster.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_policy_attachment" "eks_s3_policy_attachment" {
  name       = "AmazonEKSS3PolicyAttachment"
  roles      = [aws_iam_role.eks_cluster.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

#resource "aws_iam_policy_attachment" "eks_efs_csi_policy_attachment" {
#  name       = "AmazonEKS_EFS_CSI_DriverRole"
#  roles      = [aws_iam_role.eks_cluster.name]  
#  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
#}

resource "aws_iam_policy" "eks_worker_node_policy" {
  name = "EKSWorkerNodePolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "eks:ListNodegroups",
          "eks:AccessKubernetesApi",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
        ],
        Resource = "*",
      }
    ],
  })
}

resource "aws_iam_role_policy_attachment" "worker_node_policy_attachment" {
  policy_arn = aws_iam_policy.eks_worker_node_policy.arn
  role       = aws_iam_role.eks_cluster.name
}


data "tls_certificate" "eks_cert" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_openid" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cert.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.eks_cert.url
}


resource "aws_eks_node_group" "wp_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "wpNodeGroup"
  node_role_arn   = aws_iam_role.eks_cluster.arn
  subnet_ids      = [aws_subnet.wp_subnet_1.id]
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker_node_policy_attachment,
    aws_iam_policy_attachment.eks_cluster_policies,
    aws_iam_policy_attachment.eks_worker_node_policy_attachment,
    aws_iam_policy_attachment.ecr_readonly_policy_attachment,
  ]
}


