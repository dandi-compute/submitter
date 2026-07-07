#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <labels_comma_separated>"
  exit 1
fi

target="${GITHUB_REPOSITORY:-}"
labels="$1"

if [ -z "$target" ]; then
  echo "Error: GITHUB_REPOSITORY is not set." >&2
  exit 1
fi

if ! command -v gh &> /dev/null; then
  echo "Error: GitHub CLI (gh) is not installed." >&2
  exit 1
fi
endpoint="repos/$target/actions/runners"

# The GitHub API occasionally returns transient errors (e.g. empty 5xx bodies
# that surface from gh as "unexpected end of JSON input"), so retry with
# exponential backoff before treating the check as failed.
max_attempts=5
delay=2
attempt=1
stderr_file=$(mktemp)
while true; do
  response=$(gh api "$endpoint" 2>"$stderr_file")
  rc=$?
  if [ $rc -eq 0 ] && echo "$response" | jq -e '.runners' > /dev/null 2>&1; then
    break
  fi
  if [ $attempt -ge $max_attempts ]; then
    echo "Error: API call failed at $endpoint after $max_attempts attempts (rc=$rc)" >&2
    echo "gh stderr: $(cat "$stderr_file")" >&2
    echo "gh stdout: $response" >&2
    rm -f "$stderr_file"
    exit 1
  fi
  echo "Warning: API call at $endpoint failed (attempt $attempt/$max_attempts, rc=$rc): $(cat "$stderr_file")" >&2
  sleep "$delay"
  delay=$((delay * 2))
  attempt=$((attempt + 1))
done
rm -f "$stderr_file"

# Split labels by comma into an array
IFS=',' read -ra label_array <<< "$labels"

# Build jq filter to check if runner has all required labels
available=$(echo "$response" | jq -r --argjson required_labels "$(printf '%s\n' "${label_array[@]}" | jq -R . | jq -s .)" '
  .runners[] | select(.status == "online") |
  select(
    ([.labels[].name] as $runner_labels |
     $required_labels | all(. as $req | $runner_labels | contains([$req])))
  )')

if [ -n "$available" ]; then
  echo "true"
else
  echo "false"
fi
