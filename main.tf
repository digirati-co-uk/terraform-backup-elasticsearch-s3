data "aws_s3_bucket" "backup_bucket" {
  bucket = "${var.s3_bucket_name}"
}

module "backup_task" {
  source = "git::https://github.com/digirati-co-uk/terraform-aws-modules.git//tf/modules/services/tasks/base/"

  environment_variables = {
    "SLACK_WEBHOOK_URL" = "${var.slack_webhook_url}"
    "S3_PREFIX"         = "s3://${data.aws_s3_bucket.backup_bucket.id}/${var.s3_key_prefix}"
    "BACKUP_NAME"       = "${var.backup_identifier}"
    "ELASTICSEARCH_URL" = "${var.elasticsearch_url}"
  }

  environment_variables_length = 4

  prefix           = "${var.prefix}"
  log_group_name   = "${var.log_group_name}"
  log_group_region = "${var.region}"
  log_prefix       = "${var.prefix}-backup-${var.backup_identifier}"

  family = "${var.prefix}-backup-${var.backup_identifier}"

  container_name = "${var.prefix}-backup-${var.backup_identifier}"

  cpu_reservation    = 0
  memory_reservation = 128

  docker_image = "${var.backup_database_s3_docker_image}"

  mount_points = [
    {
      sourceVolume  = "${var.prefix}-backup-${var.backup_identifier}-elasticsearch"
      containerPath = "/data"
    },
    {
      sourceVolume  = "${var.prefix}-backup-${var.backup_identifier}-temp"
      containerPath = "/tmp"
    },
  ]
}

resource "aws_ecs_task_definition" "backup_task" {
  family                = "${var.prefix}-backup-${var.backup_identifier}"
  container_definitions = "${module.backup_task.task_definition_json}"
  task_role_arn         = "${module.backup_task.role_arn}"

  volume {
    name      = "${var.prefix}-backup-${var.backup_identifier}-elasticsearch"
    host_path = "${var.elasticsearch_data_folder}"
  }

  volume {
    name      = "${var.prefix}-backup-${var.backup_identifier}-temp"
    host_path = "${var.temp_folder}"
  }
}

data "aws_iam_policy_document" "backup_bucket_access" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${data.aws_s3_bucket.backup_bucket.arn}/${var.s3_key_prefix}*",
      "${data.aws_s3_bucket.backup_bucket.arn}/${var.s3_key_prefix}/*",
    ]
  }
}

resource "aws_iam_role_policy" "backup_bucket_access" {
  name   = "${var.prefix}-backup-bucket-access"
  role   = "${module.backup_task.role_name}"
  policy = "${data.aws_iam_policy_document.backup_bucket_access.json}"
}

module "backup" {
  source = "git::https://github.com/digirati-co-uk/terraform-aws-modules.git//tf/modules/services/tasks/scheduled/"

  family              = "${var.prefix}-backup-${var.backup_identifier}"
  task_role_name      = "${module.backup_task.role_name}"
  region              = "${var.region}"
  account_id          = "${var.account_id}"
  cluster_arn         = "${var.cluster_id}"
  schedule_expression = "${var.cron_expression}"
  desired_count       = 1
  task_definition_arn = "${aws_ecs_task_definition.backup_task.arn}"
}
