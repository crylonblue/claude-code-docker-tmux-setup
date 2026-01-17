#!/usr/bin/env bash
set -e

REPO_URL="$1"
SESSION="claude"

if [ -z "$REPO_URL" ]; then
  echo "Usage: container <github-repo-url>"
  exit 1
fi

# --- Fix workspace ownership (runs as root initially) ---
if [ "$(id -u)" = "0" ]; then
  echo "🔧 Fixing workspace ownership..."
  chown -R claude:claude /workspace
  # Re-exec as claude user
  exec su -s /bin/bash claude -- "$0" "$@"
fi

# --- hard-disable git prompts ---
export GIT_TERMINAL_PROMPT=0

# --- mark /workspace as safe (ownership differs due to volume mount) ---
git config --global --add safe.directory /workspace

# --- Configure git user identity ---
if [ -n "$GIT_USER_NAME" ]; then
  git config --global user.name "$GIT_USER_NAME"
  echo "✅ Git user.name set to: $GIT_USER_NAME"
else
  echo "⚠️  GIT_USER_NAME not set - commits will fail"
fi

if [ -n "$GIT_USER_EMAIL" ]; then
  git config --global user.email "$GIT_USER_EMAIL"
  echo "✅ Git user.email set to: $GIT_USER_EMAIL"
else
  echo "⚠️  GIT_USER_EMAIL not set - commits will fail"
fi

# Debug: verify token received in container
echo "🔍 Debug (container): GITHUB_TOKEN length=${#GITHUB_TOKEN}, starts with=${GITHUB_TOKEN:0:4}..."

if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ GITHUB_TOKEN not set"
  exit 1
fi

# --- Configure git credential helper for pushing ---
git config --global credential.helper store
echo "https://${GITHUB_TOKEN}@github.com" > ~/.git-credentials
chmod 600 ~/.git-credentials
echo "✅ Git credentials configured for push/pull"

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
