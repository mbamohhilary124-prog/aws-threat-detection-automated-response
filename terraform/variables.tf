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
