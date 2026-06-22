#!/usr/bin/env bash
set -euo pipefail

DOCS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "Generating documentation for modules..."

generate() {
  local dir="$1"
  local module_name
  module_name=$(basename "$dir")
  if [ ! -f "$dir/main.tf" ]; then
    echo "  Skipping $module_name (no main.tf)"
    return
  fi
  echo "  Generating $module_name..."
  terraform-docs markdown table --output-file README.md --output-mode inject "$dir"
}

for module in modules/aks modules/postgresql; do
  generate "$DOCS_DIR/$module"
done

for module in modules/*/; do
  generate "$DOCS_DIR/$module"
done

echo "Done!"
