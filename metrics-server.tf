
resource "helm_release" "metrics-server" {
  name      = "metrics-server"
  namespace = "default"

  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
}
