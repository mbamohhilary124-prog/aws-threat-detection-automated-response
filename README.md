\# AWS Threat Detection and Automated Response



!\[Status](https://img.shields.io/badge/status-in%20development-yellow)

!\[AWS](https://img.shields.io/badge/cloud-AWS-FF9900)

!\[Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC)



\## Project Overview



This project demonstrates an AWS security-monitoring and automated incident-response environment built with Terraform and Python.



The environment will collect audit activity, detect suspicious behavior, centralize security findings, route selected events, and initiate controlled response workflows.



> **Project status:** In development. Features will be marked complete only after deployment and validation.



\## Business Problem



Manually reviewing and responding to cloud-security findings can delay containment and create inconsistent remediation. This project demonstrates how AWS-native services can improve visibility, detection, alerting, and repeatable incident response.



\## Planned Architecture



```mermaid

flowchart TD

&#x20;   CT\["AWS CloudTrail"] --> S3\["Encrypted S3 Logs"]

&#x20;   GD\["Amazon GuardDuty"] --> SH\["AWS Security Hub"]

&#x20;   CF\["AWS Config"] --> SH

&#x20;   SH --> EB\["Amazon EventBridge"]

&#x20;   EB --> LA\["AWS Lambda"]

&#x20;   LA --> SNS\["Amazon SNS Alert"]

```



\## Planned Security Controls



\- CloudTrail audit logging

\- Encrypted S3 log storage

\- GuardDuty threat detection

\- Security Hub findings aggregation

\- AWS Config monitoring

\- EventBridge security-event routing

\- Least-privilege Lambda execution role

\- Python-based automated response

\- SNS security notifications

\- Terraform security scanning

\- GitHub Actions with AWS OIDC authentication

\- No permanent AWS credentials stored in GitHub



\## Repository Structure



```text

.

â”œâ”€â”€ .github/workflows/    # CI/CD and security scanning

â”œâ”€â”€ diagrams/             # Architecture diagrams

â”œâ”€â”€ docs/                 # Deployment and testing evidence

â”œâ”€â”€ lambda/               # Python response functions

â”œâ”€â”€ terraform/            # AWS infrastructure as code

â”œâ”€â”€ tests/                # Automated tests

â”œâ”€â”€ .gitignore

â”œâ”€â”€ README.md

â””â”€â”€ SECURITY.md

```



\## Learning Objectives



1\. Provision AWS security services with Terraform.

2\. Apply least-privilege IAM permissions.

3\. Centralize AWS security findings.

4\. Build event-driven security automation.

5\. Test detection and response workflows safely.

6\. Document technical decisions and evidence.

7\. Integrate security checks into CI/CD.



\## Prerequisites



\- AWS account

\- AWS CLI

\- Terraform

\- Git and GitHub

\- PowerShell or another terminal



\## Cost and Cleanup



Some services may generate AWS charges. Resources will be deployed only when required and removed with Terraform after validation. Detailed cost and cleanup instructions will be added before deployment.



\## Security Notice



This repository must not contain credentials, Terraform state, AWS account numbers, private keys, or unsanitized findings.



\## Author



**Hilary Mbamoh Pemamboh**

Cloud Security Engineer

Dallas, Texas
