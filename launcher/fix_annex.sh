#!/bin/bash
#
# Un-annex files matching `*.<ext> annex.largefiles=nothing` rules from
# .gitattributes by enumerating with `git annex find` (which works correctly
# with --include) and then passing explicit paths to `git annex unannex`
# (which is reliable on explicit paths).
#
# Run from the repo root.

set -euo pipefail

if [ ! -f .gitattributes ]; then
    echo "ERROR: no .gitattributes in $(pwd)" >&2
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
if [ "$(pwd)" != "$REPO_ROOT" ]; then
    echo "ERROR: run this from the repo root ($REPO_ROOT)" >&2
    exit 1
fi

# --- Parse extensions from .gitattributes ---------------------------------

mapfile -t EXTS < <(
    grep -E '^\*\.[A-Za-z0-9_]+[[:space:]]+annex\.largefiles=nothing([[:space:]]|$)' .gitattributes \
        | sed -E 's/^\*\.([A-Za-z0-9_]+).*/\1/' \
        | sort -u
)

if [ "${#EXTS[@]}" -eq 0 ]; then
    echo "No '*.<ext> annex.largefiles=nothing' rules found in .gitattributes." >&2
    exit 1
fi

echo "Extensions to un-annex (from .gitattributes): ${EXTS[*]}"

# --- 1. Enumerate matching annexed files ----------------------------------

LIST=$(mktemp)
trap 'rm -f "$LIST"' EXIT

for ext in "${EXTS[@]}"; do
    git annex find --include="*.$ext" . -- >> "$LIST"
done

n=$(wc -l < "$LIST")
echo "Matching annexed files: $n"

if [ "$n" -eq 0 ]; then
    echo "Nothing to do."
    exit 0
fi

# --- 2. Ensure content is present locally for every file ------------------

echo
echo "Fetching any missing content..."
xargs -d '\n' -a "$LIST" -r -n 100 git annex get --

missing_count=0
while IFS= read -r f; do
    if [ ! -e "$f" ]; then
        echo "  MISSING: $f" >&2
        missing_count=$((missing_count + 1))
    fi
done < "$LIST"

if [ "$missing_count" -gt 0 ]; then
    echo "ERROR: $missing_count file(s) missing content; aborting." >&2
    exit 1
fi

# --- 3. Unannex each file with an explicit path ---------------------------

echo
echo "Unannexing $n files..."
# -n 50: batch size, small enough to keep argv reasonable, large enough to
# avoid 78 separate process launches. -r: don't run with empty input.
xargs -d '\n' -a "$LIST" -r -n 50 git annex unannex --

# --- 4. Report and commit -------------------------------------------------

echo
echo "Status after unannex:"
git status --short | head -40
n_changed=$(git status --short | wc -l)
echo "  ${n_changed} entries changed"

# Sanity check: confirm count of still-annexed matching files dropped to 0
remaining=0
for ext in "${EXTS[@]}"; do
    r=$(git annex find --include="*.$ext" . | wc -l)
    remaining=$((remaining + r))
done
echo "  Still-annexed matching files: $remaining (should be 0)"

if [ "$remaining" -gt 0 ]; then
    echo "WARNING: some files were not unannexed. Investigate before committing." >&2
    exit 1
fi

git add .gitattributes
git add -A
if git diff --cached --quiet; then
    echo "Nothing to commit."
    exit 0
fi

git commit -m "Un-annex ${EXTS[*]} files (track in git directly)"

echo
echo "Commit created. Review with:"
echo "  git log -1 --stat | head -40"
echo
echo "When ready, publish with:"
echo "  datalad push --to github"
