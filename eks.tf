# Create an EKS cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "EKSCluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = [aws_subnet.wp_subnet_1.id, aws_subnet.wp_subnet_2.id]
  }
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
        Effect   = "Allow",
        Action   = [
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


# Create a Kubernetes configuration file
data "aws_eks_cluster_auth" "eks_cluster_auth" {
  name = aws_eks_cluster.eks_cluster.name

  depends_on = [aws_eks_cluster.eks_cluster]
}

# Define a Kubernetes provider using the generated configuration file
provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks_cluster_auth.token
}

# Create a Kubernetes namespace
#resource "kubernetes_namespace" "namespace" {
#  metadata {
#    name = "wordpress"
#  }
#}

#resource "aws_launch_template" "worker_nodes" {
#  name = "WorkerNodes"
#  #  image_id = "ami-09f67f6dc966a7829"
#  instance_type = "t3.small"
#  vpc_security_group_ids = [aws_security_group.eks_security_group.id]
#}




resource "aws_eks_node_group" "wp_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "wpNodeGroup"
  node_role_arn   = aws_iam_role.eks_cluster.arn
  subnet_ids      = [aws_subnet.wp_subnet_1.id]

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  #  launch_template {
  #    id      = aws_launch_template.worker_nodes.id
  #    version = "$Latest"
  #  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.worker_node_policy_attachment,
    aws_iam_policy_attachment.eks_cluster_policies,
    aws_iam_policy_attachment.eks_worker_node_policy_attachment,
    aws_iam_policy_attachment.ecr_readonly_policy_attachment,
  ]
}

#module "fully-loaded-eks-cluster_aws-efs-csi-driver" {
#  source  = "bootlabstech/fully-loaded-eks-cluster/aws//modules/kubernetes-addons/aws-efs-csi-driver"
#  version = "1.0.7"
#  # insert the 1 required variable here
#}

#resource "helm_release" "cluster-autoscaler" {
#  name      = "ClusterAutoscaler"
#
#  repository = "https://kubernetes.github.io/autoscaler"
#  chart      = "cluster-autoscaler"
#
#  set {
#    name  = "autoDiscovery.clusterName"
#    value = aws_eks_cluster.eks_cluster.name
#  }
#  set {
#    name  = "awsRegion"
#    value = data.aws_region.current.name 
#  }
#  debug = true
#  wait  = true
#  set {
#    name  = "awsAccessKeyID"
#    value = "AKIAS7MPH75HAIEKH34W" 
#  }
#  set {
#    name  = "awsSecretAccessKey"
#    value = "jcLUckCiRvygBCHGVcieadS+6yu535r6zGUXfB+d" 
#  }
#}

