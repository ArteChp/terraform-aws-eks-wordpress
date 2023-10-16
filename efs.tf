

resource "aws_security_group" "efs_security_group" {
  name        = "EFSSecurityGroup"
  description = "EFS security group"
  vpc_id      = aws_vpc.sb_vpc.id

  ingress = [
    {
      description      = "In TCP EFS"
      from_port        = 2049
      to_port          = 2049
      protocol         = "tcp"
      cidr_blocks      = [aws_vpc.sb_vpc.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
  ]
}

resource "kubernetes_storage_class" "efs-sc" {
  metadata {
    name = "efs-sc"
  }

  storage_provisioner = "efs.csi.aws.com"

  reclaim_policy = "Retain"

  #  parameters = {
  #    provisioningMode = "efs-ap"
  #    fileSystemId = aws_efs_file_system.efs.id
  #    directoryPerms = "700"
  #    gidRangeStart = "1000"
  #    gidRangeEnd = "2000"
  #    basePath = "/data"
  #  }
  #  
  #  # allow_volume_expansion = true
  #  # 
  #  # volume_binding_mode = "Immediate"
}

# Create an AWS EFS File System
resource "aws_efs_file_system" "efs" {
  creation_token = "eks-efs"
}

resource "kubernetes_storage_class" "efs-ap-sc" {
  metadata {
    name = "efs-ap-sc"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "efs.csi.aws.com"

  reclaim_policy = "Retain"

  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = aws_efs_file_system.efs.id
    directoryPerms   = "700"
    basePath         = "/dynam_data"
  }

  # allow_volume_expansion = true
  # 
  # volume_binding_mode = "Immediate"
}

resource "aws_efs_mount_target" "efs_mount" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.wp_subnet_1.id
  security_groups = [aws_security_group.efs_security_group.id]
}


resource "helm_release" "aws_efs_csi_driver" {
  name       = "aws-efs-csi-driver"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart      = "aws-efs-csi-driver"

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.us-west-1.amazonaws.com/eks/aws-efs-csi-driver"
  }

  set {
    name  = "controller.serviceAccount.create"
    value = "false"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "efs-csi-controller-sa"
  }

  #  set {
  #    name  = "useFips"
  #    value = "true"
  #  }
}


resource "kubernetes_service_account" "efs_csi_service_account" {
  metadata {
    name      = "efs-csi-controller-sa"
    namespace = "kube-system"

    labels = {
      "app.kubernetes.io/name" = "aws-efs-csi-driver"
    }

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.efs_csi_driver_role.arn
    }
  }
}



resource "aws_iam_policy" "efs_csi_driver_policy" {
  name        = "EFSCSIDriverPolicy"
  description = "IAM policy for EFS CSI Driver access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeMountTargets",
          "ec2:DescribeAvailabilityZones"
        ],
        Resource = "*",
      },
      {
        Effect = "Allow",
        Action = [
          "elasticfilesystem:CreateAccessPoint"
        ],
        Resource = "*",
        Condition = {
          StringLike = {
            "aws:RequestTag/efs.csi.aws.com/cluster" = "true"
          }
        },
      },
      {
        Effect = "Allow",
        Action = [
          "elasticfilesystem:TagResource"
        ],
        Resource = "*",
        Condition = {
          StringLike = {
            "aws:ResourceTag/efs.csi.aws.com/cluster" = "true"
          }
        },
      },
      {
        Effect   = "Allow",
        Action   = "elasticfilesystem:DeleteAccessPoint",
        Resource = "*",
        Condition = {
          StringEquals = {
            "aws:ResourceTag/efs.csi.aws.com/cluster" = "true"
          }
        },
      },
    ],
  })
}


data "aws_iam_policy_document" "efs_csi_driver_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_openid.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:efs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_openid.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "efs_csi_driver_role" {
  name               = "EFSCSIDriverRole"
  assume_role_policy = data.aws_iam_policy_document.efs_csi_driver_assume_role_policy.json
}

resource "aws_iam_policy_attachment" "efs_csi_driver_policy_attachment" {
  name       = "EFSCSIDriverRolePolicyAttachment"
  roles      = [aws_iam_role.efs_csi_driver_role.name]
  policy_arn = aws_iam_policy.efs_csi_driver_policy.arn
}
