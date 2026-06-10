#!/usr/bin/env bash
set -euo pipefail
source "$HOME/.dandi_env"

curl -fsS -X POST \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/dandi-compute/submitter/actions/workflows/process_queue.yml/dispatches \
  -d '{"ref":"main"}'
