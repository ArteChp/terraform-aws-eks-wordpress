
resource "kubernetes_deployment" "wordpress" {
  metadata {
    name = "wordpress-${var.id}"
  }

  spec {
    selector {
      match_labels = {
        app = "wordpress-${var.id}"
      }
    }

    template {
      metadata {
        labels = {
          app = "wordpress-${var.id}"
        }
        # annotations = {
        #   "prometheus.io/scrape" = "true"
        #   "prometheus.io/port" = "9000"
        # }
      }

      spec {
        container {
          name  = "wordpress-${var.id}"
          image = var.wp_container_image
          #image = "docker.io/library/wordpress:latest"

          volume_mount {
            name       = "wp-content-${var.id}"
            mount_path = "/bitnami/wordpress"
          }

          env {
            name  = "WORDPRESS_DATABASE_HOST"
            value = var.mysql_service_name 
          }

          env {
            name  = "WORDPRESS_DATABASE_USER"
            value = var.wp_db_user 
          }

          env {
            name  = "WORDPRESS_DATABASE_PASSWORD"
            value = var.wp_db_pass 
          }

          env {
            name  = "WORDPRESS_DATABASE_NAME"
            value = var.wp_db_name 
          }

          env {
            name  = "WORDPRESS_TABLE_PREFIX"
            value = var.wp_db_prefix 
          }

          env {
            name  = "MYSQL_CLIENT_DATABASE_ROOT_PASSWORD"
            value = var.wp_db_root_pass
          }

          env {
            name  = "MYSQL_CLIENT_CREATE_DATABASE_NAME"
            value = var.wp_db_name
          }

          env {
            name  = "MYSQL_CLIENT_CREATE_DATABASE_USER"
            value = var.wp_db_user
          }

          env {
            name  = "MYSQL_CLIENT_CREATE_DATABASE_PASSWORD"
            value = var.wp_db_pass
          }

          port {
            container_port = "8080"
            name = "http"
          }

        }
        volume {
          name = "wp-content-${var.id}"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.wp-content-cl.metadata[0].name
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "wordpress" {
  metadata {
    name = "wordpress-${var.id}"
    # annotations = {
    #   "prometheus.io/scrape" = "true"
    #   "prometheus.io/port" = "9000"
    # }
  }

  spec {
    selector = {
      app = kubernetes_deployment.wordpress.metadata[0].name
    }

    port {
      # protocol    = "TCP"
      port        = 8080 
      target_port = 8080 
      name = "http"
    }

  }
}


resource "kubernetes_persistent_volume_claim" "wp-content-cl" {
  metadata {
    name = "wp-content-${var.id}-cl"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = var.wp_storage_size
      }
    }
    # volume_name        = "wp-content-${var.id}"
    storage_class_name = "efs-ap-sc"
  }
}






