# Backup Elasticsearch S3

Terraform module for scheduled backing up of a single Elasticsearch instance, with notifications sent to a Slack webhook.

The container that the module uses (`digirati/backup-elasticsearch-s3` - see https://github.com/digirati-co-uk/backup-elasticsearch-s3) will attempt to flush the targeted Elasticsearch instance before tar-balling the mapped-in data volume to the specified temporary volume. The file will have the timestamp of the operation appended to its name and will be uploaded to the specified location in S3.

## Parameters

| Variable                        | Description                                                                                     | Default                            |
|---------------------------------|-------------------------------------------------------------------------------------------------|------------------------------------|
| prefix                          | Prefix to give to AWS resources                                                                 |                                    |
| slack_webhook_url               | Slack Webhook URL for notifications                                                             |                                    |
| log_group_name                  | CloudWatch log group name that the container will emit logs to                                  |                                    |
| backup_elasticsearch_s3_docker_image | The Docker image to use for the ECS Task                                                        | digirati/backup-elasticsearch-s3:latest |
| region                          | AWS Region for resources                                                                        |                                    |
| s3_key_prefix                   | The prefix for the S3 key to be used for backups                                                |                                    |
| s3_bucket_name                  | The name of the S3 bucket that will hold backups                                                |                                    |
| account_id                      | AWS account ID                                                                                  |                                    |
| cluster_id                      | The cluster on which to run the scheduled ECS task                                              |                                    |
| cron_expression                 | Cron scheduling expression in form `cron(x x x x x x)`                                          |                                    |
| elasticsearch_data_folder | Host volume to map into container as `/data` | |
| elasticsearch_url | Fully qualified URL of the Elasticsearch instance to back up (e.g. http://elasticsearch.internal:9200) | |
| temp_folder | Host volume to use as temporary space (mapped into container as `/tmp`) | |
| 

## Example

```
module "backup_elasticsearch" {
  source                          = "git::https://github.com/digirati-co-uk/terraform-backup-elasticsearch-s3.git//"
  slack_webhook_url               = "${var.slack_webhook_status}"
  log_group_name                  = "${var.log_group_name}"
  prefix                          = "${var.prefix}"
  backup_identifier               = "elasticsearch"
  region                          = "${var.region}"
  s3_key_prefix                   = "backups/elasticsearch/"
  s3_bucket_name                  = "${var.bootstrap_objects_bucket}"
  account_id                      = "${var.account_id}"
  cluster_id                      = "${module.metropolis_cluster.cluster_id}"
  cron_expression                 = "cron(0 0 * * ? *)"
  elasticsearch_data_folder       = "/data-ebs/${var.prefix}-elasticsearch"
  elasticsearch_url               = "http://elasticsearch.${var.internal_domain}:9200"
  temp_folder                     = "/data-ebs/${var.prefix}-backup-elasticsearch"
}

```

## File name format

The default filename format uses `date +%Y%m%d%H%M` to produce a timestamp.

For further information, see https://github.com/digirati-co-uk/backup-elasticsearch-s3#s3_prefix

## Permissions

The following Terraform snippet shows the AWS permissions required for this module:

```
data "aws_iam_policy_document" "backup_bucket_access" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${var.backup_bucket_arn}/${var.s3_key_prefix}*",
      "${var.backup_bucket_arn}/${var.s3_key_prefix}/*",
    ]
  }
}
```
