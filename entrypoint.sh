#!/usr/bin/env bash
set -e

REPO_URL="$1"
SESSION="claude"

if [ -z "$REPO_URL" ]; then
  echo "Usage: container <github-repo-url>"
  exit 1
fi

# --- hard-disable git prompts ---
export GIT_TERMINAL_PROMPT=0

# Debug: verify token received in container
echo "🔍 Debug (container): GITHUB_TOKEN length=${#GITHUB_TOKEN}, starts with=${GITHUB_TOKEN:0:4}..."

if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ GITHUB_TOKEN not set"
  exit 1
fi

# Inject token directly into URL (CI-safe)
AUTHED_REPO_URL="$(echo "$REPO_URL" | sed -E "s#https://#https://${GITHUB_TOKEN}@#")"
echo "🔍 Debug (container): URL constructed, token injected at position 8-$((8 + ${#GITHUB_TOKEN}))"

# Clone repo if needed
if [ ! -d "/workspace/.git" ]; then
  echo "📥 Cloning repo..."
  git clone "$AUTHED_REPO_URL" /workspace

  # Optional: remove token from origin after clone
  git -C /workspace remote set-url origin "$REPO_URL"
fi

cd /workspace

# tmux session
if tmux has-session -t "$SESSION" 2>/dev/null; then
  exec tmux attach -t "$SESSION"
fi

tmux new -s "$SESSION" -d
tmux send-keys -t "$SESSION:1" "claude --dangerously-skip-permissions ." C-m

exec tmux attach -t "$SESSION"
