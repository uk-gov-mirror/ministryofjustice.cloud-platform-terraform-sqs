# cloud-platform-terraform-sqs

[![Releases](https://img.shields.io/github/v/release/ministryofjustice/cloud-platform-terraform-sqs.svg)](https://github.com/ministryofjustice/cloud-platform-terraform-sqs/releases)

This Terraform module will create an [Amazon Simple Queue Service (SQS)](https://aws.amazon.com/sqs/) queue for use on the Cloud Platform.

## Usage

```hcl
module "sqs" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-sqs?ref=version" # use the latest release

  # Queue configuration
  sqs_name        = "example"
  encrypt_sqs_kms = "true"

  # Tags
  business_unit          = var.business_unit
  application            = var.application
  is_production          = var.is_production
  team_name              = var.team_name # also used for naming the queue
  namespace              = var.namespace
  environment_name       = var.environment
  infrastructure_support = var.infrastructure_support
}
```

### Access policy

SQS topics must be allowed access to either read or write, depending on application design, via an IAM policy.

Due to [a glitch](https://github.com/hashicorp/terraform/issues/4354) in the AWS API, TF cannot create the queue policy in a single step, so a separate resource type has been defined. To use, add in the same /resources/:

```hcl
resource "aws_sqs_queue_policy" "example_sqs_policy" {
  queue_url = "${module.example_sqs.sqs_id}"

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Id": "${module.example_sqs.sqs_arn}/SQSDefaultPolicy",
    "Statement":
      [
        {
          "Effect": "Allow",
          "Principal": {"AWS": "*"},
          "Resource": "${module.example_sqs.sqs_arn}",
          "Action": "SQS:SendMessage",
          "Condition":
            {
              "ArnEquals":
                {
                  "aws:SourceArn": "${module.example_sns.topic_arn}"
                }
              }
        }
      ]
  }
  EOF
}
```

Note the reference to an SNS topic, which needs to be defined in the same namespace.

### Redrive policy

Messages that cannot be parsed are copied to a "dead letter" queue the ARN of which can be specified inline:

```hcl
redrive_policy = <<EOF
  {
    "deadLetterTargetArn": "${module.example_dead_letter_queue.sqs_arn}","maxReceiveCount": 1
  }
  EOF
```

See the [examples/](examples/) folder for more information.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 2.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.irsa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_kms_alias.alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_sqs_queue.terraform_queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [random_id.id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.irsa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name | `string` | n/a | yes |
| <a name="input_business_unit"></a> [business\_unit](#input\_business\_unit) | Area of the MOJ responsible for the service | `string` | n/a | yes |
| <a name="input_content_based_deduplication"></a> [content\_based\_deduplication](#input\_content\_based\_deduplication) | Enables content-based deduplication for FIFO queues. | `bool` | `null` | no |
| <a name="input_deduplication_scope"></a> [deduplication\_scope](#input\_deduplication\_scope) | Specifies whether message deduplication occurs at the message group or queue level. Valid values are `messageGroup` and `queue`. | `string` | `null` | no |
| <a name="input_delay_seconds"></a> [delay\_seconds](#input\_delay\_seconds) | The time in seconds that the delivery of all messages in the queue will be delayed. An integer from 0 to 900 (15 minutes). | `number` | `0` | no |
| <a name="input_encrypt_sqs_kms"></a> [encrypt\_sqs\_kms](#input\_encrypt\_sqs\_kms) | If set to true, this will create aws\_kms\_key and aws\_kms\_alias resources and add kms\_master\_key\_id in aws\_sqs\_queue resource | `bool` | `false` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Environment name | `string` | n/a | yes |
| <a name="input_fifo_queue"></a> [fifo\_queue](#input\_fifo\_queue) | FIFO means exactly-once processing. Duplicates are not introduced into the queue. | `bool` | `false` | no |
| <a name="input_fifo_throughput_limit"></a> [fifo\_throughput\_limit](#input\_fifo\_throughput\_limit) | Specifies whether the FIFO queue throughput quota applies to the entire queue or per message group. Valid values are `perQueue` (default) and `perMessageGroupId`. | `string` | `null` | no |
| <a name="input_github_team"></a> [github\_team](#input\_github\_team) | The slug of the GitHub team with access to the SQS queue via the AWS Console | `string` | `null` | no |
| <a name="input_infrastructure_support"></a> [infrastructure\_support](#input\_infrastructure\_support) | The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>) | `string` | n/a | yes |
| <a name="input_is_production"></a> [is\_production](#input\_is\_production) | Whether this is used for production or not | `string` | n/a | yes |
| <a name="input_kms_data_key_reuse_period_seconds"></a> [kms\_data\_key\_reuse\_period\_seconds](#input\_kms\_data\_key\_reuse\_period\_seconds) | The length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again. An integer representing seconds, between 60 seconds (1 minute) and 86,400 seconds (24 hours). | `number` | `300` | no |
| <a name="input_kms_external_access"></a> [kms\_external\_access](#input\_kms\_external\_access) | A list of external AWS principals (e.g. account ids, or IAM roles) that can access the KMS key, to enable cross-account message decryption. | `list(string)` | `[]` | no |
| <a name="input_max_message_size"></a> [max\_message\_size](#input\_max\_message\_size) | The limit of how many bytes a message can contain before Amazon SQS rejects it. An integer from 1024 bytes (1 KiB) up to 1048576 bytes (1 MiB). | `number` | `262144` | no |
| <a name="input_message_retention_seconds"></a> [message\_retention\_seconds](#input\_message\_retention\_seconds) | The number of seconds Amazon SQS retains a message. Integer representing seconds, from 60 (1 minute) to 1209600 (14 days). | `number` | `345600` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace name | `string` | n/a | yes |
| <a name="input_receive_wait_time_seconds"></a> [receive\_wait\_time\_seconds](#input\_receive\_wait\_time\_seconds) | The time for which a ReceiveMessage call will wait for a message to arrive (long polling) before returning. An integer from 0 to 20 (seconds). | `number` | `0` | no |
| <a name="input_redrive_policy"></a> [redrive\_policy](#input\_redrive\_policy) | escaped JSON string to set up the Dead Letter Queue | `any` | `""` | no |
| <a name="input_sqs_name"></a> [sqs\_name](#input\_sqs\_name) | SQS queue name | `string` | n/a | yes |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | Team name | `string` | n/a | yes |
| <a name="input_visibility_timeout_seconds"></a> [visibility\_timeout\_seconds](#input\_visibility\_timeout\_seconds) | The visibility timeout for the queue. An integer from 0 to 43200 (12 hours). | `number` | `30` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_irsa_policy_arn"></a> [irsa\_policy\_arn](#output\_irsa\_policy\_arn) | IAM policy ARN for access to the SQS queue |
| <a name="output_sqs_arn"></a> [sqs\_arn](#output\_sqs\_arn) | The ARN of the SQS queue |
| <a name="output_sqs_id"></a> [sqs\_id](#output\_sqs\_id) | The URL for the created Amazon SQS queue |
| <a name="output_sqs_name"></a> [sqs\_name](#output\_sqs\_name) | The name of the SQS queue |
<!-- END_TF_DOCS -->

## Tags

Some of the inputs for this module are tags. All infrastructure resources must be tagged to meet the MOJ Technical Guidance on [Documenting owners of infrastructure](https://technical-guidance.service.justice.gov.uk/documentation/standards/documenting-infrastructure-owners.html).

You should use your namespace variables to populate these. See the [Usage](#usage) section for more information.

## Team name caveat

This module utilises your environment `team_name` variable in the naming of your SQS topic, in the format `<var.team_name>-<var.environment_name><var.sqs_name>`. This historically introduced an issue whereby a team name change would result in Terraform forcefully replacing the SQS topic. To get around this issue, a [lifecycle](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle) `ignore_changes` block has been introduced, so that team name changes can be made without causing this issue.

However, its important to note that if you do change the team name in your environment variables, it will not be reflected in the SQS topic name. If you want to update the name, you will need to look at deleting and recreating your SQS topic(s).

## Reading Material

- [Cloud Platform user guide](https://user-guide.cloud-platform.service.justice.gov.uk/#cloud-platform-user-guide)
- [Amazon Simple Queue Service (SQS) developer guide](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/welcome.html)

