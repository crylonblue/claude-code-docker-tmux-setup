# Claude Code Docker + tmux Setup

A Docker-based development environment for running [Claude Code](https://github.com/anthropics/claude-code) with tmux session management.

## Features

- **Containerized Claude Code**: Runs Claude Code in an isolated Docker environment
- **tmux Integration**: Persistent terminal sessions with custom configuration
- **GitHub Integration**: Automatic repository cloning with token authentication
- **Workspace Persistence**: Local workspace volumes preserve your work between sessions

## Prerequisites

- Docker installed and running
- GitHub Personal Access Token with repo access
- Anthropic API key (set via environment or Claude Code login)

## Setup

1. **Create a `.env` file** in the project directory:

```bash
GITHUB_TOKEN=ghp_your_github_token_here
CLAUDE_MODEL=claude-sonnet-4-20250514  # optional, defaults to latest
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your.email@example.com"
```

2. **Build the Docker image**:

```bash
docker build -t claude-dev:latest .
```

3. **Make the launcher script executable**:

```bash
chmod +x claude-dev
```

## Usage

Run Claude Code on any GitHub repository:

```bash
./claude-dev https://github.com/owner/repository
```

This will:
1. Create a local workspace directory at `~/.claude-workspaces/<repo-name>/`
2. Clone the repository (if not already cloned)
3. Start a tmux session with Claude Code running

### tmux Controls

- **Mouse support**: Enabled by default
- **Split horizontally**: `Ctrl+b` then `|`
- **Split vertically**: `Ctrl+b` then `-`
- **Detach session**: `Ctrl+b` then `d`
- **Reattach**: The container will automatically reattach to existing sessions

## Configuration

### Claude Settings

The `claude-settings.json` file is copied to `/home/claude/.claude/settings.json` in the container. This pre-configures Claude Code to skip the initial onboarding wizard.

```json
{
  "hasCompletedOnboarding": true,
  "theme": "dark",
  "permissions": {
    "allow": [],
    "deny": []
  },
  "env": {}
}
```

Available theme options: `"dark"`, `"light"`, `"light-daltonized"`, `"dark-daltonized"`

### tmux Configuration

The `tmux.conf` file contains tmux settings. Current defaults:
- Mouse support enabled
- 100,000 line scroll history
- 1-based window/pane indexing
- Custom status bar

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `GITHUB_TOKEN` | GitHub PAT for cloning repos | Required |
| `GIT_USER_NAME` | Git author name for commits | Required |
| `GIT_USER_EMAIL` | Git author email for commits | Required |
| `CLAUDE_MODEL` | Claude model to use | Latest |
| `DOCKER_IMAGE` | Docker image name | `claude-dev:latest` |
| `WORKSPACE_BASE` | Local workspace directory | `~/.claude-workspaces` |

## Project Structure

```
.
├── Dockerfile          # Container definition
├── entrypoint.sh       # Container startup script
├── claude-dev          # Host launcher script
├── claude-settings.json # Claude Code configuration
├── tmux.conf           # tmux configuration
└── README.md           # This file
```

## Security Notes

- The `--dangerously-skip-permissions` flag is used to allow Claude Code full filesystem access within the container
- GitHub tokens are stored in `~/.git-credentials` inside the container (not persisted outside)
- The container starts as root to fix workspace ownership, then switches to the `claude` user
- Workspaces are isolated per repository

## License

MIT
