import json
import subprocess
import unittest
from pathlib import Path


FILTER = Path(__file__).with_name("terraform-plan-counts.jq")


def count_changes(changes):
    result = subprocess.run(
        ["jq", "-ec", "-f", str(FILTER)],
        input=json.dumps({"resource_changes": changes}),
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)


class TerraformPlanCountsTest(unittest.TestCase):
    def test_counts_changes_and_both_replacement_orders(self):
        changes = [
            {"mode": "managed", "change": {"actions": actions}}
            for actions in (
                ["create"],
                ["update"],
                ["delete"],
                ["delete", "create"],
                ["create", "delete"],
                ["no-op"],
            )
        ]
        changes.append({"mode": "data", "change": {"actions": ["read"]}})
        self.assertEqual(count_changes(changes), {"add": 3, "change": 1, "delete": 3})

    def test_no_resource_changes(self):
        self.assertEqual(count_changes([]), {"add": 0, "change": 0, "delete": 0})


if __name__ == "__main__":
    unittest.main()
