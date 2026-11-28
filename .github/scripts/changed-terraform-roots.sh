#!/usr/bin/env bash
set -euo pipefail

roots="$(jq -sc '
  [ .[] | (.filename, (.previous_filename // empty))
    | select(startswith("terraform/"))
    | split("/")
    | select(length >= 3)
    | .[1]
  ] | unique
' "$1")"

if ! jq -e 'all(.[]; test("^[A-Za-z0-9][A-Za-z0-9._-]*$"))' <<< "$roots" > /dev/null; then
  echo "Terraform root names must contain only letters, numbers, dots, underscores, and hyphens, and start with a letter or number." >&2
  exit 1
fi

if [ "$(jq 'length' <<< "$roots")" -gt 256 ]; then
  echo "More than 256 Terraform roots changed; GitHub Actions cannot run this matrix." >&2
  exit 1
fi

while IFS= read -r root; do
  directory="terraform/$root"
  if [ ! -d "$directory" ] || [ -z "$(find "$directory" -maxdepth 1 -type f \( -name '*.tf' -o -name '*.tf.json' -o -name '*.tofu' -o -name '*.tofu.json' \) -print -quit)" ]; then
    echo "Terraform root $directory is missing or has no configuration; destroy or migrate its resources before removing it." >&2
    exit 1
  fi
  if [ ! -f "$directory/1password.env" ]; then
    echo "Terraform root $directory is missing its 1password.env reference file." >&2
    exit 1
  fi
done < <(jq -r '.[]' <<< "$roots")

echo "$roots"
