
data "aws_secretsmanager_secret" "mysql_root" {
  name = "dev/root/mysql"
}

data "aws_secretsmanager_secret_version" "mysql_root" {
  secret_id = data.aws_secretsmanager_secret.mysql_root.id
}

data "aws_secretsmanager_secret" "mysql_user1" {
  name = "dev/user1/mysql"
}

data "aws_secretsmanager_secret_version" "mysql_user1" {
  secret_id = data.aws_secretsmanager_secret.mysql_user1.id
}

variable "source_account_id" {
  description = "AWS account ID"
  type        = string
  default     = "204848234318"
}

#variable "mysql_root_pass" {
#  description = "The password for the MySQL DB"
#  type        = string
#  sensitive   = true
#}

#variable "mysql_wp1_pass" {
#  description = "The password for the MySQL DB of Wordpress 1"
#  type        = string
#  sensitive   = true
#}
#
#variable "mysql_wp2_pass" {
#  description = "The password for the MySQL DB of Wordpress 2"
#  type        = string
#  sensitive   = true
#}
#
#variable "mysql_wp3_pass" {
#  description = "The password for the MySQL DB of Wordpress 3"
#  type        = string
#  sensitive   = true
#}
#
#variable "mysql_wp4_pass" {
#  description = "The password for the MySQL DB of Wordpress 4"
#  type        = string
#  sensitive   = true
#}
