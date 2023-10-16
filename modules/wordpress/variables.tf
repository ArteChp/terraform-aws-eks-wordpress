variable "id" {
  description = "Id of the WordPress "
  type        = string
}

variable "mysql_service_name" {
  description = "Name of the MySQL service used by WordPress."
  type        = string
}

variable "wp_container_image" {
  description = "Name of the WordPress service used by Swag."
  type        = string
}

variable "wp_db_name" {
  description = "Name of the WordPress database."
  type        = string
}

variable "wp_db_user" {
  description = "Name of the WordPress database user."
  type        = string
}

variable "wp_db_pass" {
  description = "Password for user of the WordPress database."
  type        = string
}

variable "wp_db_root_pass" {
  description = "Password for root user of the WordPress database."
  type        = string
}

variable "wp_db_prefix" {
  description = "Table prefix of the WordPress database."
  type        = string
}

variable "wp_storage_size" {
  description = "Size of the WordPress storage."
  type        = string
  default     = "5Gi"
}

variable "wp_debug" {
  description = "Name of the WordPress container image."
  type        = string
  default     = "false"
}

variable "domain" {
  description = "Name of the domain."
  type        = string
}


