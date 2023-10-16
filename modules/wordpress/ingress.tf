
# resource "kubernetes_config_map_v1" "ingress_cm" {
#   metadata {
#     name = "ingress-cm-${var.id}"
#   }
#
#   data = {
#     DOCUMENT_ROOT = "/var/www/html"
#     SCRIPT_FILENAME = "/var/www/html/$fastcgi_script_name"
#   }
# }

resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name = "ingress-${var.id}"
    annotations = {
      # "ingress.kubernetes.io/rewrite-target" = "/$1"
      # "kubernetes.io/ingress.class"          = "nginx"
      "cert-manager.io/issuer"               = "selfsigned-issuer"
      # "nginx.ingress.kubernetes.io/backend-protocol"               = "FCGI"
      # "nginx.ingress.kubernetes.io/fastcgi-index"               = "index.php"
      # "nginx.ingress.kubernetes.io/fastcgi-params-configmap"               = "default/ingress-cm"
      # "nginx.ingress.kubernetes.io/fastcgi-params-configmap"               = "ingress-cm-${var.id}"
      # "nginx.ingress.kubernetes.io/configuration-snippet" = <<CONFIG_SNIPPET
      #   location / {
      #     try_files $uri $uri/ /index.php$is_args$args;
      #   }
      #   CONFIG_SNIPPET
      # "nginx.ingress.kubernetes.io/configuration-snippet" = <<CONFIG_SNIPPET
      #   location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
      #           expires max;
      #           log_not_found off;
      #   }
      #  CONFIG_SNIPPET

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
  # depends_on = [kubernetes_config_map_v1.ingress_cm]
}

