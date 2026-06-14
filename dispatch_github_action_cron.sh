#!/usr/bin/env bash
set -euo pipefail
source "$HOME/.dandi_env"

# Skip during cluster maintenance windows: SLURM holds our pending jobs with
# "Reserved for maintenance" in the reason column, so dispatching more is futile.
maintenance_threshold=5
maintenance_held=$(
  squeue --me --noheader --states=PENDING --format='%100R' \
    | grep -c 'Reserved for maintenance' || true
)
if (( maintenance_held >= maintenance_threshold )); then
  echo "Detected ${maintenance_held} jobs reserved for maintenance (threshold ${maintenance_threshold}); skipping dispatch."
  exit 0
fi

module load miniforge
conda activate /orcd/data/dandi/001/environments/name-dandi+compute_env

if ! dandicompute queue pending --silent; then
  echo "No pending queue entries; skipping dispatch."
  exit 0
fi

curl -fsS -X POST \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/dandi-compute/submitter/actions/workflows/process-queue.yml/dispatches \
  -d '{"ref":"main"}'
