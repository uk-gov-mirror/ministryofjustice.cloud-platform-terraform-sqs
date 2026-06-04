#################
# Configuration #
#################

# Resource variables
variable "visibility_timeout_seconds" {
  description = "The visibility timeout for the queue. An integer from 0 to 43200 (12 hours)."
  default     = 30
  type        = number
}

variable "message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message. Integer representing seconds, from 60 (1 minute) to 1209600 (14 days)."
  default     = 345600
  type        = number
}

variable "max_message_size" {
  description = "The limit of how many bytes a message can contain before Amazon SQS rejects it. An integer from 1024 bytes (1 KiB) up to 1048576 bytes (1 MiB)."
  default     = 262144
  type        = number
}

variable "delay_seconds" {
  description = "The time in seconds that the delivery of all messages in the queue will be delayed. An integer from 0 to 900 (15 minutes)."
  default     = 0
  type        = number
}

variable "receive_wait_time_seconds" {
  description = "The time for which a ReceiveMessage call will wait for a message to arrive (long polling) before returning. An integer from 0 to 20 (seconds)."
  default     = 0
  type        = number
}

variable "redrive_policy" {
  description = "escaped JSON string to set up the Dead Letter Queue"
  default     = ""
  type        = any
}

variable "fifo_queue" {
  description = "FIFO means exactly-once processing. Duplicates are not introduced into the queue."
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enables content-based deduplication for FIFO queues."
  type        = bool
  default     = null
}

variable "deduplication_scope" {
  description = "Specifies whether message deduplication occurs at the message group or queue level. Valid values are `messageGroup` and `queue`."
  type        = string
  default     = null
}

variable "fifo_throughput_limit" {
  description = "Specifies whether the FIFO queue throughput quota applies to the entire queue or per message group. Valid values are `perQueue` (default) and `perMessageGroupId`."
  type        = string
  default     = null
}

variable "kms_data_key_reuse_period_seconds" {
  description = "The length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again. An integer representing seconds, between 60 seconds (1 minute) and 86,400 seconds (24 hours)."
  default     = 300
  type        = number
}

# Custom variables
variable "kms_external_access" {
  description = "A list of external AWS principals (e.g. account ids, or IAM roles) that can access the KMS key, to enable cross-account message decryption."
  type        = list(string)
  default     = []
}

variable "sqs_name" {
  description = "SQS queue name"
  type        = string
}

variable "encrypt_sqs_kms" {
  description = "If set to true, this will create aws_kms_key and aws_kms_alias resources and add kms_master_key_id in aws_sqs_queue resource"
  type        = bool
  default     = false
}

########
# Tags #
########
variable "business_unit" {
  description = "Area of the MOJ responsible for the service"
  type        = string
}

variable "application" {
  description = "Application name"
  type        = string
}

variable "is_production" {
  description = "Whether this is used for production or not"
  type        = string
}

variable "team_name" {
  description = "Team name"
  type        = string
}

variable "namespace" {
  description = "Namespace name"
  type        = string
}

variable "environment_name" {
  description = "Environment name"
  type        = string
}

variable "infrastructure_support" {
  description = "The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>)"
  type        = string
}

variable "github_team" {
  description = "The slug of the GitHub team with access to the SQS queue via the AWS Console"
  type        = string
  default     = null
}
