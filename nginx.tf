
resource "helm_release" "ingress-nginx" {
  name = "ingress-nginx"
  # namespace = "ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.7.2"

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-eip-allocations"
    value = aws_eip.sb_dev.id
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-subnets"
    value = aws_subnet.wp_subnet_1.id
  }

  set {
    name  = "rbac.create"
    value = "true"
  }

  depends_on = [aws_eks_cluster.eks_cluster]
}

