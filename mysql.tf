

resource "kubernetes_stateful_set" "mysql" {
  metadata {
    name = "mysql"
  }

  spec {
    service_name = "mysql-service"
    #   replicas     = 2

    selector {
      match_labels = {
        app = "mysql"
      }
    }

    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }

      spec {
        container {
          name  = "mariadb"
          image = "docker.io/bitnami/mariadb:10.6.15-debian-11-r49"
          port {
            name           = "mysql"
            container_port = 3306
          }
          volume_mount {
            name       = "mysql-data"
            mount_path = "/bitnami/mariadb"
          }
          env {
            name  = "MARIADB_ROOT_PASSWORD"
            value = jsondecode(data.aws_secretsmanager_secret_version.mysql_root.secret_string)["password"]
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "mysql-data"
      }

      spec {
        access_modes       = ["ReadWriteMany"]
        volume_name        = "mysql-data"
        storage_class_name = "efs-sc"

        resources {
          requests = {
            storage = "3Gi"
          }
        }
      }
    }
  }
}


# Create an AWS EFS Access Point
resource "aws_efs_access_point" "mysql_efs" {
  file_system_id = aws_efs_file_system.efs.id
  posix_user {
    uid = "1001"
    gid = "1001"
  } 
  root_directory {
    path = "/mysql_data"
  }
}

resource "kubernetes_persistent_volume" "mysql_data" {
  metadata {
    name = "mysql-data"
  }
  spec {
    capacity = {
      storage = "3Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      csi {
        driver        = "efs.csi.aws.com"
        volume_handle = aws_efs_access_point.mysql_efs.file_system_id
      }
    }
    storage_class_name = "efs-sc"
  }

  depends_on = [aws_eks_cluster.eks_cluster, aws_efs_access_point.mysql_efs]
}

resource "kubernetes_service" "mysql-service" {
  metadata {
    name = "mysql-service"
  }

  spec {
    selector = {
      app = "mysql"
    }

    port {
      name        = "mysql"
      protocol    = "TCP"
      port        = 3306
      target_port = 3306
    }
  }
}

output "mysql_cluster_ip" {
  value = kubernetes_service.mysql-service.spec[0].cluster_ip
}


