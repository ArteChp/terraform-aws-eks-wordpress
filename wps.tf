


module "wp1" {
  id                 = "1"
  mysql_service_name = kubernetes_service.mysql-service.metadata.0.name
  source             = "./modules/wordpress"
  wp_container_image = "bitnami/wordpress-nginx:6.3.2-debian-11-r0"
  wp_db_name         = jsondecode(data.aws_secretsmanager_secret_version.mysql_user1.secret_string)["dbname"]
  wp_db_user         = jsondecode(data.aws_secretsmanager_secret_version.mysql_user1.secret_string)["username"]
  wp_db_pass         = jsondecode(data.aws_secretsmanager_secret_version.mysql_user1.secret_string)["password"]
  wp_db_root_pass    = jsondecode(data.aws_secretsmanager_secret_version.mysql_root.secret_string)["password"]
  wp_db_prefix       = "wp_"
  wp_debug           = "1"
  domain             = "domain1.com"
}

