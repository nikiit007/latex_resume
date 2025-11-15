#!/usr/bin/env bash

set -euo pipefail

SOURCE_REL="overleaf_nikhil/PDF/resume.pdf"
DEST_DIR="/mnt/c/Users/nikhi/Documents/resume"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "This script must be run inside a Git repository." >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

ALLOW_DIRTY="${ALLOW_DIRTY:-0}"
if [[ -n "$(git status --porcelain)" && "$ALLOW_DIRTY" != "1" ]]; then
  echo "Please commit or stash your changes before running this script, or set ALLOW_DIRTY=1." >&2
  exit 1
fi

mapfile -t BRANCHES < <(git for-each-ref --format='%(refname:short)' refs/heads)

if [[ ${#BRANCHES[@]} -eq 0 ]]; then
  echo "No local branches found."
  exit 0
fi

mkdir -p "$DEST_DIR"

STARTING_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

restore_branch() {
  git switch -q "$STARTING_BRANCH"
}
trap restore_branch EXIT

for BRANCH in "${BRANCHES[@]}"; do
  echo "Processing branch '$BRANCH'..."
  if [[ "$BRANCH" != "$(git rev-parse --abbrev-ref HEAD)" ]]; then
    git switch -q "$BRANCH"
  fi

  SOURCE_PDF="$REPO_ROOT/$SOURCE_REL"
  if [[ ! -f "$SOURCE_PDF" ]]; then
    echo "  Skipped: '$SOURCE_REL' not found on this branch."
    continue
  fi

  SAFE_BRANCH="${BRANCH//\//_}"
  DEST_PATH="$DEST_DIR/Nikhil_Ranjan_${SAFE_BRANCH}.pdf"
  cp "$SOURCE_PDF" "$DEST_PATH"
  echo "  Copied to $DEST_PATH"
done

echo "All done. PDFs saved under $DEST_DIR"
