"""Unit tests for the safe GuardDuty automated-response Lambda."""

import json
import sys
import unittest
from pathlib import Path

LAMBDA_DIRECTORY = Path(__file__).resolve().parents[1] / "lambda"
sys.path.insert(0, str(LAMBDA_DIRECTORY))

import response_handler


def create_guardduty_event(
    severity: float = 8.0,
    resource_type: str = "Instance",
) -> dict:
    """Create a small, fictional GuardDuty event for local testing."""

    return {
        "version": "0",
        "id": "test-event-id",
        "detail-type": "GuardDuty Finding",
        "source": "aws.guardduty",
        "account": "000000000000",
        "region": "us-east-1",
        "detail": {
            "id": "test-finding-id",
            "type": "Backdoor:EC2/DenialOfService.Tcp",
            "severity": severity,
            "title": "Fictional GuardDuty finding for local testing",
            "resource": {
                "resourceType": resource_type,
            },
        },
    }


class TestGuardDutyResponseHandler(unittest.TestCase):
    """Verify safe response decisions without calling AWS."""

    def test_high_severity_ec2_finding_creates_dry_run_decision(self):
        event = create_guardduty_event(
            severity=8.0,
            resource_type="Instance",
        )

        response = response_handler.lambda_handler(event, None)
        body = json.loads(response["body"])

        self.assertEqual(response["statusCode"], 200)
        self.assertEqual(body["decision"], "DRY_RUN_RECORDED")
        self.assertEqual(body["proposed_action"], "ISOLATE_EC2_INSTANCE")
        self.assertTrue(body["dry_run"])

    def test_low_severity_finding_is_ignored(self):
        event = create_guardduty_event(
            severity=2.0,
            resource_type="Instance",
        )

        response = response_handler.lambda_handler(event, None)
        body = json.loads(response["body"])

        self.assertEqual(body["decision"], "IGNORED")
        self.assertEqual(body["proposed_action"], "NONE")

    def test_non_guardduty_event_is_rejected(self):
        event = create_guardduty_event()
        event["source"] = "aws.ec2"

        response = response_handler.lambda_handler(event, None)
        body = json.loads(response["body"])

        self.assertEqual(body["decision"], "REJECTED")
        self.assertIn("not Amazon GuardDuty", body["reason"])

    def test_unknown_resource_requires_manual_investigation(self):
        event = create_guardduty_event(
            severity=6.0,
            resource_type="UnknownResource",
        )

        response = response_handler.lambda_handler(event, None)
        body = json.loads(response["body"])

        self.assertEqual(body["decision"], "DRY_RUN_RECORDED")
        self.assertEqual(body["proposed_action"], "MANUAL_INVESTIGATION")


if __name__ == "__main__":
    unittest.main()
