"""Safe automated-response handler for Amazon GuardDuty findings.

This first version operates in DRY-RUN mode. It evaluates a GuardDuty
finding and records the response that would be taken, but it does not
modify any AWS resource.
"""

import json
import logging
import os
from typing import Any

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

MINIMUM_SEVERITY = float(os.getenv("MINIMUM_SEVERITY", "4.0"))
DRY_RUN = os.getenv("DRY_RUN", "true").lower() == "true"

RESPONSE_BY_RESOURCE_TYPE = {
    "Instance": "ISOLATE_EC2_INSTANCE",
    "AccessKey": "DISABLE_COMPROMISED_ACCESS_KEY",
    "S3Bucket": "BLOCK_S3_PUBLIC_ACCESS",
    "EKSCluster": "RESTRICT_EKS_ACCESS",
    "ECSCluster": "RESTRICT_ECS_WORKLOAD",
    "Container": "ISOLATE_CONTAINER_WORKLOAD",
}


def build_response_decision(detail: dict[str, Any]) -> dict[str, Any]:
    """Build a safe response decision from a GuardDuty finding."""

    severity = float(detail.get("severity", 0))
    finding_type = detail.get("type", "Unknown")
    finding_id = detail.get("id", "Unknown")

    resource = detail.get("resource") or {}
    resource_type = resource.get("resourceType", "Unknown")

    proposed_action = RESPONSE_BY_RESOURCE_TYPE.get(
        resource_type,
        "MANUAL_INVESTIGATION",
    )

    if severity < MINIMUM_SEVERITY:
        return {
            "decision": "IGNORED",
            "reason": "Finding severity is below the configured threshold.",
            "finding_id": finding_id,
            "finding_type": finding_type,
            "severity": severity,
            "resource_type": resource_type,
            "proposed_action": "NONE",
            "dry_run": DRY_RUN,
        }

    return {
        "decision": "DRY_RUN_RECORDED" if DRY_RUN else "ACTION_NOT_IMPLEMENTED",
        "reason": (
            "Approved finding evaluated safely; no AWS resource was modified."
            if DRY_RUN
            else "Live remediation is intentionally not implemented yet."
        ),
        "finding_id": finding_id,
        "finding_type": finding_type,
        "severity": severity,
        "resource_type": resource_type,
        "proposed_action": proposed_action,
        "dry_run": DRY_RUN,
    }


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """AWS Lambda entry point for EventBridge GuardDuty events."""

    LOGGER.info(
        json.dumps(
            {
                "message": "GuardDuty automated-response event received",
                "event_source": event.get("source", "Unknown"),
                "detail_type": event.get("detail-type", "Unknown"),
            }
        )
    )

    if event.get("source") != "aws.guardduty":
        result = {
            "decision": "REJECTED",
            "reason": "The event source is not Amazon GuardDuty.",
            "dry_run": DRY_RUN,
        }
    elif event.get("detail-type") != "GuardDuty Finding":
        result = {
            "decision": "REJECTED",
            "reason": "The event is not a GuardDuty Finding.",
            "dry_run": DRY_RUN,
        }
    else:
        detail = event.get("detail") or {}
        result = build_response_decision(detail)

    LOGGER.info(json.dumps(result, default=str))

    return {
        "statusCode": 200,
        "body": json.dumps(result),
    }
