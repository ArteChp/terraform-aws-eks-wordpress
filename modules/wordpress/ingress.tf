

resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name = "ingress-${var.id}"
    annotations = {
      "cert-manager.io/issuer"               = "selfsigned-issuer"
    }
  }

  spec {
    ingress_class_name = "nginx"
    tls {
      hosts       = ["${var.domain}"]
      secret_name = "domain-tls-${var.id}"
    }
    rule {
      host = var.domain
      http {
        path {
          backend {
            service {
              name = kubernetes_service.wordpress.metadata[0].name
              port {
                number = kubernetes_service.wordpress.spec[0].port[0].port
              }
            }
          }

          path = "/"
        }
      }
    }
  }
}

