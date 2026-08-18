locals {
  common_tags = {
    Project     = "aws-threat-detection-automated-response"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Hilary Mbamoh Pemamboh"
    Repository  = "aws-threat-detection-automated-response"
  }
}
