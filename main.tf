locals {
  # Generic configuration
  queue_name = var.fifo_queue ? "${var.team_name}-${var.environment_name}-${var.sqs_name}.fifo" : "${var.team_name}-${var.environment_name}-${var.sqs_name}"

  # Tags
  default_tags = {
    # Mandatory
    business-unit = var.business_unit
    application   = var.application
    is-production = var.is_production
    owner         = var.team_name
    namespace     = var.namespace # for billing and identification purposes

    # Optional
    environment-name       = var.environment_name
    infrastructure-support = var.infrastructure_support
    GithubTeam             = var.github_team
  }
}

###########################
# Get account information #
###########################
data "aws_caller_identity" "current" {}

########################
# Generate identifiers #
########################
resource "random_id" "id" {
  byte_length = 6
}

#########################
# Create encryption key #
#########################
resource "aws_kms_key" "kms" {
  description = "KMS key for ${local.queue_name}"
  count       = var.encrypt_sqs_kms ? 1 : 0
  tags = local.default_tags

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-policy"
    Statement = [
      {
        Sid    = "Allow administration of the key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion",
          "kms:TagResource",
          "kms:UntagResource"
        ],
        Resource = "*"
      },
      {
        Sid    = "Allow s3 use of the key"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        },
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ],
        Resource = "*"
      },
      {
        Sid    = "Allow SNS use of the key"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        },
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ],
        Resource = "*"
      },
      {
        Sid    = "Allow IAM use of the key"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        },
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ],
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "Allow cross-account use of the key"
        Effect = "Allow"
        Principal = {
          AWS = length(var.kms_external_access) >= 1 ? var.kms_external_access : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
        },
        Action = [
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:Decrypt",
          "kms:Encrypt"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "alias" {
  count         = var.encrypt_sqs_kms ? 1 : 0
  name          = "alias/${replace(local.queue_name, ".", "-")}" # aliases can't have `.` in their name, so we replace them with a `-` (useful if this is a FIFO queue)
  target_key_id = aws_kms_key.kms[0].key_id
}

################
# Create queue #
################
resource "aws_sqs_queue" "terraform_queue" {
  name = local.queue_name

  visibility_timeout_seconds        = var.visibility_timeout_seconds
  message_retention_seconds         = var.message_retention_seconds
  max_message_size                  = var.max_message_size
  delay_seconds                     = var.delay_seconds
  receive_wait_time_seconds         = var.receive_wait_time_seconds
  kms_data_key_reuse_period_seconds = var.kms_data_key_reuse_period_seconds
  kms_master_key_id                 = var.encrypt_sqs_kms ? aws_kms_key.kms[0].arn : null
  redrive_policy                    = var.redrive_policy

  # FIFO
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.content_based_deduplication
  deduplication_scope         = var.deduplication_scope
  fifo_throughput_limit       = var.fifo_throughput_limit

  tags = local.default_tags

  lifecycle {
    ignore_changes = [name]
  }

}

##############################
# Create IAM role for access #
##############################
data "aws_iam_policy_document" "irsa" {
  version = "2012-10-17"
  statement {
    sid       = "AllowSQSActionsFor${random_id.id.hex}" # this is set to include the hex, so you can merge policies
    effect    = "Allow"
    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.terraform_queue.arn]
  }
}

resource "aws_iam_policy" "irsa" {
  name   = "cloud-platform-sqs-${random_id.id.hex}"
  path   = "/cloud-platform/sqs/"
  policy = data.aws_iam_policy_document.irsa.json
  tags   = local.default_tags
}
