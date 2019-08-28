variable "slack_webhook_url" {}
variable "log_group_name" {}
variable "prefix" {}
variable "backup_identifier" {}
variable "region" {}
variable "elasticsearch_data_folder" {}
variable "elasticsearch_url" {}

variable "temp_folder" {}

variable "backup_elasticsearch_s3_docker_image" {
  default = "digirati/backup-elasticsearch-s3:latest"
}

variable "s3_key_prefix" {}
variable "s3_bucket_name" {}
variable "account_id" {}
variable "cluster_id" {}
variable "cron_expression" {}
