#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "Clearing credentials..."
rm -rf .credentials/claude/* .credentials/claude/.* .credentials/codex/* .credentials/codex/.*

echo "Done. Run ./develop.sh to start fresh."
