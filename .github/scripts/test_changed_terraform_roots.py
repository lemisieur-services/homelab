import json
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("changed-terraform-roots.sh")


class ChangedTerraformRootsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.workspace = Path(self.temp.name)

    def add_root(self, name):
        root = self.workspace / "terraform" / name
        root.mkdir(parents=True)
        (root / "main.tf").touch()
        (root / "1password.env").touch()

    def discover(self, files):
        file_list = self.workspace / "files.jsonl"
        file_list.write_text("".join(json.dumps(item) + "\n" for item in files))
        return subprocess.run(
            ["bash", str(SCRIPT), str(file_list)],
            cwd=self.workspace,
            capture_output=True,
            text=True,
            check=False,
        )

    def test_discovers_unique_roots_including_both_sides_of_renames(self):
        self.add_root("dns")
        self.add_root("other")
        result = self.discover([
            {"filename": "terraform/dns/zones/zone.yaml"},
            {"filename": "terraform/dns/main.tf"},
            {"filename": "terraform/other/main.tf", "previous_filename": "terraform/dns/old.tf"},
            {"filename": "terraform/README.md"},
            {"filename": "k8s/example.yaml"},
        ])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), ["dns", "other"])

    def test_ignores_changes_outside_roots(self):
        result = self.discover([{"filename": "terraform/README.md"}])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), [])

    def test_rejects_removed_roots(self):
        result = self.discover([{"filename": "terraform/removed/main.tf"}])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("destroy or migrate", result.stderr)

    def test_rejects_root_without_secret_reference_file(self):
        self.add_root("dns")
        (self.workspace / "terraform/dns/1password.env").unlink()
        result = self.discover([{"filename": "terraform/dns/main.tf"}])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("1password.env", result.stderr)

    def test_rejects_invalid_root_names(self):
        result = self.discover([{"filename": "terraform/bad name/main.tf"}])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("root names", result.stderr)


if __name__ == "__main__":
    unittest.main()
