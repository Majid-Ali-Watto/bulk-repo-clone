#!/usr/bin/env bash
set -euo pipefail

# Set to "ssh" or "https". You can also override at runtime with:
#   URL_TYPE=ssh ./clone_all.sh
#   URL_TYPE=https ./clone_all.sh
URL_TYPE="${URL_TYPE:-https}"
case "$URL_TYPE" in
  ssh|https) ;;
  *)
    echo "URL_TYPE must be either 'ssh' or 'https'." >&2
    exit 1
    ;;
esac

CONCURRENCY="${CONCURRENCY:-6}"

# Folder where all repositories will be saved
TARGET_DIR="${TARGET_DIR:-$HOME/Documents/repos}"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR" || exit 1

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is not installed. Install it from https://cli.github.com/ and run 'gh auth login'." >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "You are not logged in to GitHub CLI. Run: gh auth login" >&2
  exit 1
fi

OWNER="$(gh api user --jq '.login')"

echo "Using GitHub account: $OWNER"
echo "Cloning repos into: $TARGET_DIR"
echo "Using URL type: $URL_TYPE"
echo "Parallel jobs: $CONCURRENCY"

repos_json="$(gh repo list "$OWNER" --limit 100 --json name,defaultBranchRef,url,sshUrl)"

if [ -z "$repos_json" ] || [ "$repos_json" = "[]" ]; then
  echo "No repositories found for $OWNER."
  exit 0
fi

process_repo() {
  local repo_url="$1"
  local default_branch="${2:-main}"
  local repo_name="${repo_url##*/}"
  repo_name="${repo_name%.git}"

  if [ -d "$repo_name" ]; then
    echo "Updating $repo_name (default branch: $default_branch)..."
    git -C "$repo_name" pull --ff-only || echo "Failed to update $repo_name" >&2
  else
    echo "Cloning $repo_name (default branch: $default_branch)..."
    git clone --branch "$default_branch" --single-branch "$repo_url" || echo "Failed to clone $repo_name" >&2
  fi
}

export -f process_repo
export TARGET_DIR

jq -r --arg type "$URL_TYPE" '
  .[] | 
  (if $type == "ssh" then .sshUrl else .url end) + "\t" + (.defaultBranchRef.name // "main")
' <<<"$repos_json" |
  xargs -n 2 -P "$CONCURRENCY" bash -c 'process_repo "$1" "$2"' _
