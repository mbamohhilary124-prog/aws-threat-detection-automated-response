# Security Policy

## Purpose

This repository is a public AWS cloud-security portfolio project. It contains demonstration infrastructure and must never contain production credentials or confidential information.

## Sensitive Information

The following must never be committed:

- AWS access key IDs
- AWS secret access keys
- AWS session tokens
- Terraform state files
- AWS account numbers
- Private keys or certificates
- Unredacted security findings
- Personal or organizational confidential information

## Credential Handling

AWS credentials must remain on the local workstation or use short-lived authentication. Permanent AWS credentials must never be stored in this repository or configured as GitHub secrets when OIDC authentication is available.

## Security-Issue Response

If sensitive information is discovered in this repository:

1. Deactivate and rotate the exposed credential immediately.
2. Remove the sensitive content from the repository.
3. Remove it from Git history when necessary.
4. Review AWS activity for unauthorized use.
5. Document the incident without republishing sensitive values.

## Supported Use

This project is intended for education and professional portfolio demonstration. Deployments should use an isolated AWS environment and must be reviewed before production use.
