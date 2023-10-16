

resource "helm_release" "cert_manager" {
  name = "cert-manager"
  # namespace = "cert-manager"

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [aws_eks_cluster.eks_cluster]
}


resource "kubernetes_manifest" "cert_manager_ci_selfsigned" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "selfsigned"
    }
    "spec" = {
      "selfSigned" = {}
    }
  }
}

resource "kubernetes_manifest" "cert_manager_ci_selfsigned_issuer" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Issuer"
    "metadata" = {
      "name"      = "selfsigned-issuer"
      "namespace" = "default"
    }
    "spec" = {
      "selfSigned" = {}
    }
  }
}

