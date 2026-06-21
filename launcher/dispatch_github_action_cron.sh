#!/usr/bin/env bash
#
# Dispatch the process-queue GitHub Action when there is pending work.
# Runs from cron every 15 minutes.

set -euo pipefail

log() { printf '[dispatch] %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

log "=== dispatch run starting (pid $$) ==="

# Single instance: a wedged run keeps the lock, so you see ONE stuck pid in `ps`
# / the log instead of a pile of duplicates masking the culprit.
LOCK_FILE="/orcd/data/dandi/001/dandi-compute/tmp/dispatch_github_action_cron.lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  log "Another dispatch run holds $LOCK_FILE; exiting."
  exit 0
fi

log "Sourcing $HOME/.dandi_env"
# shellcheck disable=SC1091
source "$HOME/.dandi_env"

# set -u does NOT catch set-but-empty; fail loudly instead of sending an empty token.
: "${GH_TOKEN:?GH_TOKEN is empty or unset after sourcing .dandi_env}"

maintenance_threshold=5
maintenance_held=$(
  squeue --me --noheader --states=PENDING --format='%100R' \
    | grep -c 'Reserved for maintenance' || true
)
log "Maintenance-held pending jobs: ${maintenance_held} (threshold ${maintenance_threshold})"
if (( maintenance_held >= maintenance_threshold )); then
  log "At/over maintenance threshold; skipping dispatch."
  exit 0
fi

# lmod init references $FPATH unguarded -> trips set -u. Relax only around modules.
log "Loading modules and activating conda environment"
set +u
source /etc/profile.d/modules.sh
module load miniforge
conda activate /orcd/data/dandi/001/environments/name-dandi+compute_env
set -u

# Bounded reachability check: separates "cron env can't reach GitHub" from
# "dispatch rejected" — the exact ambiguity we couldn't see before.
log "Checking GitHub API reachability"
gh_ping=$(curl -sS --max-time 10 -o /dev/null -w '%{http_code}' \
  https://api.github.com 2>&1) \
  || die "Cannot reach api.github.com from this environment: ${gh_ping}"
log "api.github.com reachable (HTTP ${gh_ping})"

log "Checking for pending queue entries"
if ! dandicompute queue pending --silent; then
  log "No pending queue entries; skipping dispatch."
  exit 0
fi
log "Pending work found; dispatching workflow"

response_body="$(mktemp)"
trap 'rm -f "$response_body"' EXIT

http_code=$(
  curl -sS --max-time 30 --retry 3 --retry-connrefused \
    -o "$response_body" -w '%{http_code}' \
    -X POST \
    -H "Authorization: Bearer $GH_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/dandi-compute/submitter/actions/workflows/process-queue.yml/dispatches \
    -d '{"ref":"main"}'
) || die "curl failed to complete the dispatch request"

if [[ "$http_code" == "204" ]]; then
  log "workflow_dispatch accepted (HTTP 204); run should appear in Actions."
else
  log "workflow_dispatch FAILED (HTTP ${http_code}); response body:"
  cat "$response_body" >&2
  exit 1
fi

log "=== dispatch run complete ==="
