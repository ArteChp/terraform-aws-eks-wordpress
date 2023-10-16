

module "aws_lb_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "AWSEKSLBRole"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.eks_openid.arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "kubernetes_service_account" "service_account" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.aws_lb_role.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}


resource "helm_release" "aws_lb_cont" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [
    kubernetes_service_account.service_account
  ]

  set {
    name  = "region"
    value = data.aws_region.current.id
  }

  set {
    name  = "vpcId"
    value = aws_vpc.sb_vpc.id
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.us-west-1.amazonaws.com/amazon/aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "clusterName"
    value = local.k8s_cluster_name
  }
}

#module "alb_controller" {
#  source  = "iplabs/alb-controller/kubernetes"
#  version = "5.0.1"
#
#  providers = {
#    kubernetes = "kubernetes.eks",
#    helm       = "helm.eks"
#  }
#
#  k8s_cluster_type = "eks"
#  k8s_namespace    = "kube-system"
#
#  aws_region_name  = data.aws_region.current.name
#  k8s_cluster_name = data.aws_eks_cluster.eks_cluster.name
#}


#resource "helm_release" "aws_lb_controller" {
#  name       = "aws-efs-csi-driver"
#  namespace  = "kube-system"
#  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
#  chart      = "aws-efs-csi-driver"
#
#  set {
#    name  = "image.repository"
#    value = "602401143452.dkr.ecr.us-west-1.amazonaws.com/eks/aws-efs-csi-driver"
#  }
#
#  set {
#    name  = "controller.serviceAccount.create"
#    value = "false"
#  }
#
#  set {
#    name  = "controller.serviceAccount.name"
#    value = "efs-csi-controller-sa"
#  }
#
#  #  set {
#  #    name  = "useFips"
#  #    value = "true"
#  #  }
#}


#data "http" "aws_lb_cont_iam_policy" {
#  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
#}
#
#
#resource "aws_iam_policy" "aws_lb_cont_iam_policy" {
#  name        = "AWSLoadBalancerControllerIAMPolicy"
#  description = "IAM policy for AWS Load Balancer Controller"
#  policy      = data.http.aws_lb_cont_iam_policy.response_body
#}

#resource "kubernetes_service_account" "aws_lb_cont_sa" {
#  metadata {
#    name      = "aws-load-balancer-controller"
#    namespace = "kube-system"
#
#    labels = {
#      "app.kubernetes.io/name" = "aws-efs-csi-driver"
#    }
#
#    annotations = {
#      "eks.amazonaws.com/role-arn" = aws_iam_role.efs_csi_driver_role.arn
#    }
#  }
#}
#
#
#
#
#
#data "aws_iam_policy_document" "efs_csi_driver_assume_role_policy" {
#  statement {
#    actions = ["sts:AssumeRoleWithWebIdentity"]
#    effect  = "Allow"
#
#    condition {
#      test     = "StringEquals"
#      variable = "${replace(aws_iam_openid_connect_provider.eks_openid.url, "https://", "")}:sub"
#      values   = ["system:serviceaccount:kube-system:efs-csi-controller-sa"]
#    }
#
#    principals {
#      identifiers = [aws_iam_openid_connect_provider.eks_openid.arn]
#      type        = "Federated"
#    }
#  }
#}
#
#resource "aws_iam_role" "efs_csi_driver_role" {
#  name               = "EFSCSIDriverRole"
#  assume_role_policy = data.aws_iam_policy_document.efs_csi_driver_assume_role_policy.json
#}
#
#resource "aws_iam_policy_attachment" "efs_csi_driver_policy_attachment" {
#  name       = "EFSCSIDriverRolePolicyAttachment"
#  roles      = [aws_iam_role.efs_csi_driver_role.name]
#  policy_arn = aws_iam_policy.efs_csi_driver_policy.arn
#}
