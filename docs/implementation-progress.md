# AWS Threat Detection and Automated Response

> A detailed implementation and learning guide for an AWS-native security-monitoring and email-alerting environment built with Terraform.

**Technologies:** Terraform, Amazon S3, AWS CloudTrail, Amazon GuardDuty, Amazon EventBridge, and Amazon SNS  
**Author:** Hilary Mbamoh Pemamboh  
**Project checkpoint:** 20 August 2026  
**Repository:** `aws-threat-detection-automated-response`


# How to use this guide

Read Chapters 1–4 first to understand the architecture and project story. Use Chapters 5–8 as a technical reference while reviewing the Terraform. Chapters 9–12 cover validation, troubleshooting, cost control, and Git discipline. The interview chapter converts the technical work into concise professional explanations. The appendix preserves sanitized source listings for study.

| **Privacy:** AWS account numbers, detector IDs, subscription IDs, bucket suffixes, email addresses, and unsubscribe links are intentionally omitted or redacted. Terraform state and plan files are not included. |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|

# Contents

- 1\. Executive overview and current project state
- 2\. Architecture and event flow
- 3\. Project chronology: what we did and why
- 4\. Terraform fundamentals used in the project
- 5\. File-by-file implementation explanation
- 6\. Security controls and design decisions
- 7\. Deployment, validation, and testing runbook
- 8\. Troubleshooting lessons
- 9\. Cost management and cleanup
- 10\. Git and GitHub workflow
- 11\. Production-hardening recommendations
- 12\. Interview-ready explanations
- 13\. Next-phase roadmap
- Appendix A. Complete sanitized Terraform source

# 1. Executive overview and current project state

This project implements an AWS-native security-monitoring foundation using Terraform. It records AWS management activity, protects audit logs, detects suspicious behavior, filters actionable GuardDuty findings, and emails structured security alerts. The design is intentionally lab-friendly, cost-aware, and suitable for a public cloud-security portfolio.

| **Capability**   | **Implementation**                      | **Verified outcome**                                                |
|------------------|-----------------------------------------|---------------------------------------------------------------------|
| Audit logging    | Multi-Region AWS CloudTrail             | Logging enabled; delivery completed without errors                  |
| Log protection   | Private, encrypted, versioned S3 bucket | Public access blocked; AES-256; ownership enforced                  |
| Threat detection | Amazon GuardDuty                        | Detector enabled; foundational sources active                       |
| Cost control     | Terraform-managed optional features     | Unused RDS, AI, runtime, EKS, S3, Lambda and malware plans disabled |
| Event filtering  | Amazon EventBridge                      | Medium, high and critical findings matched at severity ≥ 4          |
| Notification     | Amazon SNS email subscription           | Subscription confirmed and sample alert received                    |
| Source control   | Git and GitHub                          | Tested milestones committed and pushed to main                      |

| **Current checkpoint:** Infrastructure is deployed in us-east-1. Terraform reports no drift after the GuardDuty cost-control change. The notification system has passed an end-to-end sample-finding test. |
|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|

# 2. Architecture and event flow

The architecture separates collection, detection, routing, and delivery. Each service has a narrow responsibility, which makes the system easier to test, secure, and extend.

| **1. Activity** | **2. Record**   | **3. Detect**     | **4. Route**     | **5. Notify** |
|-----------------|-----------------|-------------------|------------------|---------------|
| AWS API actions | CloudTrail → S3 | GuardDuty finding | EventBridge rule | SNS → email   |

## 2.1 Audit path

1.  A user, service, or automation calls an AWS API.
2.  CloudTrail records management events across Regions and global services.
3.  CloudTrail writes validated log files to the dedicated S3 bucket.
4.  S3 protects the evidence through public-access blocking, enforced ownership, versioning, encryption, and HTTPS-only access.

## 2.2 Detection and alert path

5.  GuardDuty analyzes foundational CloudTrail, DNS, and VPC flow telemetry.
6.  A GuardDuty finding is published to EventBridge as a structured event.
7.  The EventBridge rule accepts GuardDuty Finding events whose numeric severity is at least 4.
8.  An input transformer extracts the title, severity, type, account, Region, and finding ID.
9.  The SNS topic receives the transformed event and emails the confirmed subscriber.

# 3. Project chronology: what we did and why

| **Milestone**         | **Action**                                                                                     | **Reason**                                                           |
|-----------------------|------------------------------------------------------------------------------------------------|----------------------------------------------------------------------|
| Repository foundation | Created README, SECURITY policy, ignore rules, folders, and Terraform placeholders.            | Establish professional structure before deploying resources.         |
| AWS CLI setup         | Resolved signature errors by recreating keys and setting us-east-1.                            | Terraform must authenticate reliably before infrastructure changes.  |
| Terraform foundation  | Added version constraints, AWS provider, variables, common tags, caller identity, and outputs. | Make the project repeatable and self-describing.                     |
| Secure storage        | Created a private, encrypted, versioned S3 log bucket.                                         | Audit evidence needs confidentiality, integrity, and recoverability. |
| CloudTrail            | Enabled multi-Region logging, global events, validation, and bucket permissions.               | Capture account activity and deliver it securely.                    |
| GuardDuty             | Enabled the detector and disabled unused optional features.                                    | Retain foundational detection while controlling lab costs.           |
| Cleanup checkpoint    | Destroyed 13 resources before pausing work.                                                    | Avoid leaving billable services active overnight.                    |
| Rebuild               | Validated configuration, planned 13 resources, applied, then verified with AWS CLI.            | Prove reproducibility and verify actual AWS state.                   |
| Drift discovery       | Found RDS login monitoring enabled by default; added RDS and AI controls.                      | Convert an AWS default into an explicit Terraform decision.          |
| Alerting              | Added EventBridge, SNS, policy, subscription, and message transformation.                      | Move from passive detection to actionable notification.              |
| End-to-end test       | Generated a safe sample GuardDuty finding and received the email.                              | Validate the whole system, not only resource creation.               |

## 3.1 Why the environment was destroyed and recreated

Terraform destroy removed the 13 managed resources when work paused. This was a deliberate cost-control decision, not a failure. Source code remained in Git, and local state recorded the destruction. The next session demonstrated Infrastructure as Code reproducibility by recreating the environment from configuration.

**Cleanup commands**

```powershell
terraform plan -destroy

terraform destroy
```

| **Important:** Destroying AWS resources does not delete the GitHub repository or Terraform configuration. Restarting a computer also does not stop cloud resources; AWS services continue until disabled or destroyed. |
|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|

# 4. Terraform fundamentals used in the project

| **Concept**      | **Meaning**                                                     | **Project example**              |
|------------------|-----------------------------------------------------------------|----------------------------------|
| Provider         | Plugin that translates Terraform resources into AWS API calls.  | hashicorp/aws ~> 6.0            |
| Resource         | An infrastructure object Terraform creates or manages.          | aws_cloudtrail.security_audit    |
| Data source      | Reads or calculates information without owning that AWS object. | data.aws_caller_identity.current |
| Variable         | An input that makes configuration reusable.                     | var.notification_email           |
| Local value      | A reusable expression internal to the module.                   | local.common_tags                |
| Output           | A selected value exposed after apply.                           | guardduty_event_rule_name        |
| State            | Terraform’s mapping between code and real resource identifiers. | terraform.tfstate (never commit) |
| Plan             | A preview of proposed actions.                                  | \+ create, ~ update, - destroy   |
| Dependency graph | Ordering inferred from references and depends_on.               | Policy before EventBridge target |
| for_each         | Creates one managed instance per set/map item.                  | GuardDuty feature controls       |
| dynamic block    | Conditionally generates nested configuration.                   | Runtime agent settings           |
| jsonencode       | Builds valid JSON from HCL structures.                          | EventBridge event pattern        |

## 4.1 Terraform lifecycle

10. terraform init prepares the directory, provider plugins, lock file, and backend.

11. terraform fmt standardizes HCL formatting.

12. terraform validate checks syntax, provider schemas, and internal references.

13. terraform plan compares desired configuration, Terraform state, and AWS reality.

14. terraform apply executes the approved plan and updates state.

15. AWS CLI verification independently checks the resulting cloud configuration.

16. terraform plan is run again to confirm no drift.

17. Git stages, reviews, commits, and pushes only non-sensitive source files.

# 5. File-by-file implementation explanation

## 5.1 versions.tf — compatibility contract

**Key source**

```hcl
terraform {

required_version = ">= 1.10.0,  6.0"

}

}

}
```

The Terraform range allows supported 1.x versions from 1.10.0 up to, but not including, 2.0.0. The AWS provider constraint ~> 6.0 accepts compatible 6.x releases while preventing an automatic major-version jump. The lock file records the actual selected provider and checksums for repeatable installs.

## 5.2 providers.tf — AWS connection and default tags

**Key source**

```hcl
provider "aws" {

region = var.aws_region

default_tags {

tags = local.common_tags

}

}
```

The provider uses var.aws_region rather than a hardcoded location. default_tags automatically applies common metadata to supported resources. This improves inventory, ownership, cost analysis, and traceability without repeating the same tags in every resource block.

## 5.3 locals.tf and data.tf — reusable metadata and identity

**Key source**

```hcl
locals {

common_tags = {

Project = "aws-threat-detection-automated-response"

Environment = var.environment

ManagedBy = "Terraform"

Owner = "Hilary Mbamoh Pemamboh"

Repository = "aws-threat-detection-automated-response"

}

}

data "aws_caller_identity" "current" {}
```

common_tags is a module-internal map. The caller-identity data source reads the authenticated principal and account context. Data sources appear in terraform state list, but they do not count as newly created AWS resources.

## 5.4 variables.tf — reusable and protected inputs

| **Variable**        | **Default**  | **Purpose and caution**                                |
|---------------------|--------------|--------------------------------------------------------|
| aws_region          | us-east-1    | Regional deployment target.                            |
| environment         | security-lab | Naming and tagging context.                            |
| allow_force_destroy | true         | Lab cleanup convenience; use false in production.      |
| notification_email  | none         | Required sensitive input with basic format validation. |

The email is supplied through terraform.tfvars, which is ignored by Git. Marking a value sensitive hides it in many Terraform displays, but it may still exist in state; sensitive does not mean encrypted or absent.

## 5.5 storage.tf — protected audit-log storage

| **Resource**        | **Reason**                                                                                |
|---------------------|-------------------------------------------------------------------------------------------|
| aws_s3_bucket       | Creates a globally unique name using a prefix; force_destroy is controlled by a variable. |
| public_access_block | Turns on all four S3 public-access protections.                                           |
| ownership_controls  | Uses BucketOwnerEnforced and disables legacy ACL ownership ambiguity.                     |
| versioning          | Retains versions for recovery and forensic resilience.                                    |
| encryption          | Applies SSE-S3 AES-256 encryption at rest.                                                |

| **Production note:** SSE-S3 is cost-efficient for the lab. A production design may require a customer-managed KMS key, key rotation, access logging, retention controls, Object Lock, replication, and a remote state backend. |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|

## 5.6 cloudtrail.tf — audit collection and bucket policy

The file builds the expected CloudTrail ARN dynamically from the AWS partition, Region, account, and local trail name. The bucket policy grants CloudTrail only the permissions required to inspect the bucket ACL and write into the account-specific AWSLogs path.

| **Policy statement**  | **Effect**                                                                                   |
|-----------------------|----------------------------------------------------------------------------------------------|
| AWSCloudTrailAclCheck | Allows s3:GetBucketAcl only for the CloudTrail service and only from the expected trail ARN. |
| AWSCloudTrailWrite    | Allows s3:PutObject into the account-specific log prefix with bucket-owner-full-control.     |
| DenyInsecureTransport | Explicitly denies every principal when aws:SecureTransport is false.                         |

The trail includes global service events, covers all Regions, validates log files, records management reads and writes, and explicitly depends on the bucket policy. That dependency prevents CloudTrail creation before the destination is authorized.

## 5.7 guardduty.tf — foundational detection with explicit cost controls

GuardDuty is enabled with a fifteen-minute finding publication frequency. A set drives one detector-feature resource per optional feature. This avoids repetitive blocks and makes cost-control intent reviewable.

| **Feature group**                 | **Status** | **Why**                                                               |
|-----------------------------------|------------|-----------------------------------------------------------------------|
| CloudTrail, DNS, VPC flow sources | Enabled    | Foundational detection telemetry.                                     |
| S3 and EKS protection             | Disabled   | No protected S3 data-event or EKS workload requirement in this phase. |
| EBS malware and runtime           | Disabled   | No EC2/ECS/EKS workloads requiring agents or scans.                   |
| RDS login events                  | Disabled   | Found enabled by default; no RDS workload in the lab.                 |
| Lambda network logs               | Disabled   | No Lambda workload yet.                                               |
| AI protection and analyst         | Disabled   | Not required for current project scope.                               |

The dynamic additional_configuration block is generated only when each.value is RUNTIME_MONITORING. It disables EC2, ECS Fargate, and EKS agent management. The conditional expression returns an empty set for every other feature, so no nested block is emitted.

## 5.8 notifications.tf — detection routing and email delivery

| **Component**       | **Responsibility**                                   | **Security detail**                           |
|---------------------|------------------------------------------------------|-----------------------------------------------|
| SNS topic           | Receives alert messages.                             | Named from environment; inherits common tags. |
| Email subscription  | Delivers messages to the local sensitive input.      | Requires out-of-band email confirmation.      |
| EventBridge rule    | Matches GuardDuty Finding events with severity ≥ 4.  | Reduces low-severity alert noise.             |
| IAM policy document | Allows SNS:Publish from EventBridge.                 | Service principal plus SourceArn restriction. |
| SNS topic policy    | Attaches the resource-based permission.              | Required for EventBridge-to-SNS invocation.   |
| Event target        | Connects the rule to SNS and transforms the message. | Explicitly waits for the topic policy.        |

The input transformer extracts accountId, finding id, Region, severity, title, and type from the GuardDuty EventBridge schema. The test email proved the message template and routing worked. Identifiers were manually removed before sharing evidence.

## 5.9 outputs.tf — useful non-secret deployment results

Outputs expose the Region, generated bucket name, alert topic name, and EventBridge rule name. The authenticated principal ARN is marked sensitive. Topic and rule names were chosen instead of full ARNs to avoid unnecessarily printing account identifiers.

## 5.10 .gitignore and .terraform.lock.hcl

.gitignore prevents state, plan files, terraform.tfvars, credentials, keys, editor files, Python caches, and virtual environments from entering Git. The provider lock file is intentionally committed because it supports reproducible dependency selection; state and variable-value files are intentionally excluded because they may contain secrets or identifiers.

# 6. Security controls and design decisions

| **Security principle** | **Project implementation**                                                                                                                       |
|------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| Least privilege        | CloudTrail can only check the destination and write to the expected prefix; EventBridge can only publish to the alert topic from the named rule. |
| Defense in depth       | S3 policy, public-access block, ownership controls, encryption, versioning, and HTTPS-only enforcement overlap.                                  |
| Auditability           | Multi-Region CloudTrail with global events and log validation.                                                                                   |
| Detection              | GuardDuty foundational telemetry and severity-filtered event routing.                                                                            |
| Data minimization      | Email is kept out of Git; identifiers are redacted from documentation.                                                                           |
| Reproducibility        | Version constraints, lock file, deterministic Terraform, saved plans, and Git history.                                                           |
| Cost governance        | Unused protection plans disabled; lab resources destroyed when work paused.                                                                      |
| Change control         | Format, validate, plan, apply, verify, drift check, stage, review, commit, push.                                                                 |

# 7. Deployment, validation, and testing runbook

## 7.1 Safe deployment sequence

**PowerShell / Terraform sequence**

```powershell
Set-Location .\terraform

terraform init

terraform fmt -check -recursive

terraform validate

terraform plan -out=deployment.tfplan

terraform apply deployment.tfplan
```

A saved plan ensures apply executes the reviewed actions. Plan files are ignored because they can contain sensitive values. The email value remains in ignored terraform.tfvars and Terraform state, not in GitHub.

## 7.2 Independent AWS verification

- S3: get-bucket-versioning, get-public-access-block, get-bucket-encryption, get-bucket-ownership-controls.
- CloudTrail: describe-trails and get-trail-status; verify IsLogging, LatestDeliveryTime, and no delivery error.
- GuardDuty: list-detectors and get-detector; verify foundational enabled and optional features disabled.
- EventBridge: describe-rule and list-targets-by-rule; verify ENABLED and correct target ID.
- SNS: list subscriptions without printing the endpoint; verify confirmation is complete.

## 7.3 End-to-end test

**Safe sample-finding test**

```powershell
aws guardduty create-sample-findings `

--detector-id $GuardDutyDetectorId `

--finding-types "Backdoor:EC2/DenialOfService.Tcp" `

--no-cli-pager
```

AWS sample findings contain fictitious data and are designed to test EventBridge rules and automation. The generated severity-8 sample matched the severity threshold, reached SNS, and produced a formatted email. The email sender was the expected SNS no-reply address.

## 7.4 Definition of done

- Terraform validate succeeds.
- Plan contains only intended changes.
- Apply completes without unexpected destruction.
- AWS CLI independently confirms each control.
- Sample alert reaches the confirmed destination.
- A final terraform plan reports no changes.
- Git stages only intended non-sensitive files.
- Local main and origin/main are synchronized.

# 8. Troubleshooting lessons

| **Issue**                       | **Symptom**                                                      | **Resolution and lesson**                                                                       |
|---------------------------------|------------------------------------------------------------------|-------------------------------------------------------------------------------------------------|
| AWS signature errors            | SignatureDoesNotMatch / IncompleteSignature                      | Recreated access keys, reconfigured CLI, verified caller identity and Region.                   |
| GuardDuty subscription error    | SubscriptionRequiredException                                    | Upgraded/activated the AWS account, then reapplied.                                             |
| Wrong PowerShell directory      | Terraform folder not found or Git scanned the user profile       | Used Set-Location and Get-Location before commands.                                             |
| Accidental home Git repository  | No commits yet on master; personal folders appeared as untracked | Renamed C:\Users\mbamo\\git to a reversible backup; confirmed real repo root.                   |
| Duplicated command text         | terraform validateterraform validate                             | Typed the exact command once; learned that malformed CLI input can mimic configuration failure. |
| Prose entered as command        | 'once' is not recognized                                         | Copied only text inside command blocks.                                                         |
| Wrong file opened               | Blank guardduty.tf or root-level variables.tf                    | Confirmed VS Code breadcrumb; copied correct content to terraform/ and removed duplicate.       |
| Variable pasted into wrong file | variable block appended to notifications.tf                      | Replaced complete files rather than editing individual lines.                                   |
| Wrong validation directory      | Root validation passed but did not test the module               | Changed to terraform/ and reran fmt and validate.                                               |
| SNS pending                     | Subscription showed PendingConfirmation                          | Clicked the AWS confirmation link, re-queried status, then tested.                              |
| CLI pager                       | -- More -- interrupted output                                    | Pressed q and set AWS_PAGER to an empty string / used --no-cli-pager.                           |

| **Working-directory rule:** Before Git or Terraform commands, read the PowerShell prompt and run Get-Location when uncertain. The directory is part of the command’s meaning. |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|

# 9. Cost management and cleanup

Restarting or shutting down the workstation does not pause AWS. Cloud services continue operating until disabled or destroyed. GuardDuty is usage-based, S3 charges for storage and requests, and CloudTrail may generate service and storage activity. Exact charges depend on Region, event volume, data sources, retention, and free-trial eligibility.

| **Cost control**               | **How it is implemented**                                          |
|--------------------------------|--------------------------------------------------------------------|
| Disable unused GuardDuty plans | Eight optional features are explicitly disabled through Terraform. |
| Severity filter                | Only findings with severity 4 or higher generate email alerts.     |
| Lab cleanup                    | allow_force_destroy permits removal of a non-empty log bucket.     |
| Destroy when paused            | terraform destroy removed 13 resources before an overnight pause.  |
| Verify before destroy          | terraform plan -destroy shows the exact removal count.             |

**Cleanup workflow**

```powershell
terraform plan -destroy

terraform destroy
```

| **Warning:** force_destroy = true is appropriate only for a disposable lab. Production audit logs normally require retention protections, approvals, backups, and non-destructive lifecycle rules. |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|

# 10. Git and GitHub workflow

The project uses small, purpose-specific commits. Infrastructure is tested before source changes are pushed. Terraform state, tfvars, plans, credentials, account identifiers, and unredacted findings remain local.

| **Commit**                                                  | **Purpose**                                                                     |
|-------------------------------------------------------------|---------------------------------------------------------------------------------|
| feat(storage): add secure security-log bucket               | Introduced the protected CloudTrail destination.                                |
| 6c616ad — feat(guardduty): enforce additional cost controls | Added RDS and AI settings after AWS verification revealed an unmanaged default. |
| 64b01a4 — feat(alerting): add GuardDuty email notifications | Added and tested EventBridge-to-SNS email alerting.                             |

**Safe commit workflow**

```powershell
git status --short

git diff --check

git add 

git diff --cached --check

git diff --cached

git commit -m "type(scope): clear purpose"

git push origin main

git status -sb
```

A clean final status of \## main...origin/main means the local main branch and GitHub’s main branch point to the same commit. It does not validate AWS; Git synchronization and infrastructure validation are separate checks.

# 11. Production-hardening recommendations

| **Area**            | **Recommendation**                                                                                                     |
|---------------------|------------------------------------------------------------------------------------------------------------------------|
| Remote state        | Move Terraform state to a protected remote backend with locking, encryption, versioning, and restricted access.        |
| Authentication      | Replace long-lived IAM user keys with AWS IAM Identity Center or short-lived federation; use GitHub OIDC for CI/CD.    |
| S3 protection       | Set force_destroy false; consider KMS, Object Lock, retention policies, access logging, and cross-account log archive. |
| Notifications       | Use encrypted topics with a correctly scoped KMS policy; add dead-letter handling and delivery monitoring.             |
| Detection coverage  | Enable workload-specific GuardDuty plans only when corresponding workloads exist and budgets are approved.             |
| Finding aggregation | Add Security Hub and centralize multi-account findings through AWS Organizations.                                      |
| Automated response  | Use least-privilege Lambda/Step Functions with allowlists, dry-run modes, approvals, idempotency, and rollback.        |
| CI/CD               | Add terraform fmt/validate, TFLint, Checkov/tfsec, secret scanning, and plan review gates.                             |
| Observability       | Add CloudWatch metrics/alarms for failed EventBridge invocations and SNS delivery failures.                            |
| Governance          | Map evidence to CIS AWS Foundations, NIST CSF/800-53, SOC 2, and organizational standards.                             |

# 12. Interview-ready explanations

## 12.1 60-second project summary

| **Suggested answer:** I built an AWS threat-detection and alerting environment with Terraform. CloudTrail records multi-Region management activity into a private, encrypted, versioned S3 bucket with log validation and HTTPS-only access. GuardDuty provides foundational threat detection, while I explicitly disabled unused workload-specific features to control cost and prevent configuration drift. I routed medium-and-higher findings through EventBridge to an SNS email topic using a least-privilege resource policy and an input transformer. I verified every layer with the AWS CLI and generated a safe GuardDuty sample finding, which successfully produced the expected email alert. I then confirmed no Terraform drift and committed only sanitized source files to GitHub. |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|

## 12.2 Strong technical talking points

- Explain why successful terraform apply is not enough: independent AWS verification catches defaults and runtime failures.
- Describe the RDS_LOGIN_EVENTS discovery as a configuration-drift and cost-governance example.
- Explain least privilege in both the CloudTrail bucket policy and SNS topic policy.
- Explain why a dynamic block and for_each made GuardDuty feature management maintainable.
- Explain why force_destroy is acceptable for a lab but inappropriate for production audit evidence.
- Explain how the sample finding proved the operational path rather than only IaC syntax.

## 12.3 STAR story: finding and fixing an unmanaged default

Situation: After recreating the lab, Terraform reported success, but direct GuardDuty inspection showed RDS login monitoring enabled even though the project had no RDS workload.

Task: Ensure the environment was cost-aware and that every optional feature had an explicit desired state.

Action: Checked current provider support, added RDS_LOGIN_EVENTS, AI_PROTECTION, and AI_ANALYST to the for_each set, validated and planned three management resources, applied them, queried AWS again, confirmed all optional features were disabled, and ran a no-drift plan.

Result: Removed an unmanaged paid-protection risk, improved Terraform coverage, and captured the decision in a focused Git commit.

# 13. Next-phase roadmap

| **Phase** | **Capability**                          | **Learning outcome**                                                                            |
|-----------|-----------------------------------------|-------------------------------------------------------------------------------------------------|
| 1         | Update README and architecture evidence | Mark completed controls and add sanitized test evidence.                                        |
| 2         | Security Hub                            | Aggregate GuardDuty and future security findings.                                               |
| 3         | AWS Config                              | Evaluate configuration compliance and resource drift.                                           |
| 4         | Least-privilege Lambda                  | Process selected findings with a dry-run response mode.                                         |
| 5         | Controlled remediation                  | Tag/isolate approved test resources; never broadly revoke or terminate without safeguards.      |
| 6         | Automated tests                         | Validate event patterns, message transformation, and Lambda logic.                              |
| 7         | GitHub Actions with OIDC                | Run formatting, validation, linting, security scans, and plan checks without static cloud keys. |

| **Next design principle:** Automated response must be constrained, observable, reversible, and least-privileged. Detection and notification are safe foundations; remediation should be added only with test resources and explicit guardrails. |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|

# Appendix A. Complete sanitized Terraform source

The listings below come from the sanitized project checkpoint. `terraform.tfvars`, state files, plan files, AWS identifiers, credentials, and email addresses are intentionally excluded.

## `versions.tf`

```hcl
terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

## `providers.tf`

```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
```

## `locals.tf`

```hcl
locals {
  common_tags = {
    Project     = "aws-threat-detection-automated-response"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Hilary Mbamoh Pemamboh"
    Repository  = "aws-threat-detection-automated-response"
  }
}
```

## `data.tf`

```hcl
data "aws_caller_identity" "current" {}
```

## `variables.tf`

```hcl
variable "aws_region" {
  description = "AWS region used to deploy the security-monitoring environment."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name applied to resources and tags."
  type        = string
  default     = "security-lab"
}

variable "allow_force_destroy" {
  description = "Allows Terraform to delete the lab log bucket and its contents during cleanup. Keep false in production."
  type        = bool
  default     = true
}

variable "notification_email" {
  description = "Email address that receives Amazon GuardDuty security alerts."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.notification_email))
    error_message = "The notification_email value must be a valid email address."
  }
}
```

## `storage.tf`

```hcl
resource "aws_s3_bucket" "security_logs" {
  bucket_prefix = "aws-security-logs-"
  force_destroy = var.allow_force_destroy
}

resource "aws_s3_bucket_public_access_block" "security_logs" {
  bucket = aws_s3_bucket.security_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "security_logs" {
  bucket = aws_s3_bucket.security_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "security_logs" {
  bucket = aws_s3_bucket.security_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "security_logs" {
  bucket = aws_s3_bucket.security_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

## `cloudtrail.tf`

```hcl
data "aws_partition" "current" {}

locals {
  cloudtrail_name = "security-audit-trail"
  cloudtrail_arn  = "arn:${data.aws_partition.current.partition}:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${local.cloudtrail_name}"
}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid     = "AWSCloudTrailAclCheck"
    effect  = "Allow"
    actions = ["s3:GetBucketAcl"]

    resources = [aws_s3_bucket.security_logs.arn]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [local.cloudtrail_arn]
    }
  }

  statement {
    sid     = "AWSCloudTrailWrite"
    effect  = "Allow"
    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.security_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [local.cloudtrail_arn]
    }
  }

  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.security_logs.arn,
      "${aws_s3_bucket.security_logs.arn}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.security_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket.json
}

resource "aws_cloudtrail" "security_audit" {
  name                          = local.cloudtrail_name
  s3_bucket_name                = aws_s3_bucket.security_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}
```

## `guardduty.tf`

```hcl
resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

locals {
  guardduty_disabled_features = toset([
    "S3_DATA_EVENTS",
    "EKS_AUDIT_LOGS",
    "EBS_MALWARE_PROTECTION",
    "RDS_LOGIN_EVENTS",
    "LAMBDA_NETWORK_LOGS",
    "RUNTIME_MONITORING",
    "AI_PROTECTION",
    "AI_ANALYST"
  ])

  guardduty_runtime_agents = toset([
    "EC2_AGENT_MANAGEMENT",
    "ECS_FARGATE_AGENT_MANAGEMENT",
    "EKS_ADDON_MANAGEMENT"
  ])
}

resource "aws_guardduty_detector_feature" "cost_control" {
  for_each = local.guardduty_disabled_features

  detector_id = aws_guardduty_detector.main.id
  name        = each.value
  status      = "DISABLED"

  dynamic "additional_configuration" {
    for_each = each.value == "RUNTIME_MONITORING" ? local.guardduty_runtime_agents : toset([])

    content {
      name   = additional_configuration.value
      status = "DISABLED"
    }
  }
}
```

## `notifications.tf`

```hcl
resource "aws_sns_topic" "guardduty_alerts" {
  name         = "${var.environment}-guardduty-alerts"
  display_name = "GuardDuty Alerts"
}

resource "aws_sns_topic_subscription" "guardduty_email" {
  topic_arn = aws_sns_topic.guardduty_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${var.environment}-guardduty-findings"
  description = "Captures medium, high, and critical Amazon GuardDuty findings."

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]

    detail = {
      severity = [{
        numeric = [">=", 4]
      }]
    }
  })
}

data "aws_iam_policy_document" "guardduty_alerts" {
  statement {
    sid    = "AllowEventBridgeToPublish"
    effect = "Allow"

    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.guardduty_alerts.arn]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.guardduty_findings.arn]
    }
  }
}

resource "aws_sns_topic_policy" "guardduty_alerts" {
  arn    = aws_sns_topic.guardduty_alerts.arn
  policy = data.aws_iam_policy_document.guardduty_alerts.json
}

resource "aws_cloudwatch_event_target" "guardduty_to_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendGuardDutyFindingToSNS"
  arn       = aws_sns_topic.guardduty_alerts.arn

  input_transformer {
    input_paths = {
      account_id = "$.detail.accountId"
      finding_id = "$.detail.id"
      region     = "$.region"
      severity   = "$.detail.severity"
      title      = "$.detail.title"
      type       = "$.detail.type"
    }

    input_template = <<TEMPLATE
{
  "alert": "Amazon GuardDuty security finding",
  "title": <title>,
  "severity": <severity>,
  "finding_type": <type>,
  "aws_account": <account_id>,
  "region": <region>,
  "finding_id": <finding_id>
}
TEMPLATE
  }

  depends_on = [aws_sns_topic_policy.guardduty_alerts]
}
```

## `outputs.tf`

```hcl
output "authenticated_principal_arn" {
  description = "ARN of the AWS identity used by Terraform."
  value       = data.aws_caller_identity.current.arn
  sensitive   = true
}

output "deployment_region" {
  description = "AWS region selected for this deployment."
  value       = var.aws_region
}

output "security_log_bucket_name" {
  description = "Name of the encrypted S3 bucket used for security logs."
  value       = aws_s3_bucket.security_logs.id
}

output "guardduty_alert_topic_name" {
  description = "Name of the SNS topic used for GuardDuty alert delivery."
  value       = aws_sns_topic.guardduty_alerts.name
}

output "guardduty_event_rule_name" {
  description = "Name of the EventBridge rule that captures GuardDuty findings."
  value       = aws_cloudwatch_event_rule.guardduty_findings.name
}
```

# Appendix B. Quick command reference

| **Purpose**        | **Command**                         |
|--------------------|-------------------------------------|
| Confirm directory  | Get-Location                        |
| Confirm Git root   | git rev-parse --show-toplevel       |
| Initialize         | terraform init                      |
| Format check       | terraform fmt -check -recursive     |
| Validate           | terraform validate                  |
| Plan               | terraform plan -out=\<name\>.tfplan |
| Apply saved plan   | terraform apply \<name\>.tfplan     |
| List state         | terraform state list                |
| Show outputs       | terraform output                    |
| Drift check        | terraform plan                      |
| Destroy preview    | terraform plan -destroy             |
| Destroy            | terraform destroy                   |
| Git status         | git status -sb                      |
| Ignored-file check | git check-ignore -v \<file\>        |

# Appendix C. Reference links

- HashiCorp AWS provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- AWS GuardDuty sample findings: https://docs.aws.amazon.com/guardduty/latest/ug/sample_findings.html
- GuardDuty with EventBridge: https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_findings_eventbridge.html
- Amazon GuardDuty pricing: https://aws.amazon.com/guardduty/pricing/
- Amazon S3 pricing: https://aws.amazon.com/s3/pricing/
- Terraform language documentation: https://developer.hashicorp.com/terraform/language

**End of learning guide**
