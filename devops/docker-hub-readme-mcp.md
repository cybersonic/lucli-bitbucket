# markdrew/bitbucket-mcp

MCP server image for Bitbucket operations, powered by LuCLI and the `bitbucket` module.

This image is intended for MCP-compatible clients that want to talk to Bitbucket through a containerized server process. Its default process is:

- `lucli mcp bitbucket`

## What this image is for

Use this image when your client expects an MCP server over stdio and you want Bitbucket capabilities available through the LuCLI Bitbucket module.

Typical use cases include:

- IDE or agent integrations
- MCP-based automation
- containerized Bitbucket access for AI tooling
- secure, reproducible Bitbucket tooling in controlled environments

This image is built from the same source as the CLI image, but this variant is optimized for MCP usage rather than direct command execution.

## Tags

- `latest` — stable release image
- `snapshot` — current development build

## Authentication

The server uses the same environment variables as the CLI image.

Common environment variables:

- `BITBUCKET_WORKSPACE`
- `BITBUCKET_REPO_SLUG`
- `BITBUCKET_AUTH_TOKEN`
- `BITBUCKET_AUTH_USER` (optional, for personal API token mode)

By default, `BITBUCKET_AUTH_TOKEN` is sent as a Bearer token.

If `BITBUCKET_AUTH_USER` is also set, the token is treated as a personal API token and sent using Basic auth.

## Usage

Run the MCP server directly with Docker:

```bash
docker run --rm -i \
  -e BITBUCKET_WORKSPACE=your-workspace \
  -e BITBUCKET_REPO_SLUG=your-repo \
  -e BITBUCKET_AUTH_TOKEN=your-token \
  markdrew/bitbucket-mcp:latest
```

Your MCP client should launch the container and communicate with it over stdin/stdout.

## MCP client configuration

The examples below show how to add this MCP server to various clients. Each one launches a Docker container that:

- `--pull=always` — pulls the latest image every time, so you always run the newest version
- `--rm` — automatically removes the container when it exits (no leftover stopped containers)
- `-i` — keeps stdin open so the MCP client can communicate with the server over stdio
- `-e VAR` — forwards the named environment variable from the host into the container

The `env` block in each config sets the actual values. Replace the placeholders with your Bitbucket credentials.

### Claude Desktop

Add to `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or `%APPDATA%/Claude/claude_desktop_config.json` (Windows):

```json
{
  "mcpServers": {
    "bitbucket": {
      "command": "docker",
      "args": [
        "run", "--pull=always", "--rm", "-i",
        "-e", "BITBUCKET_REPO_SLUG",
        "-e", "BITBUCKET_WORKSPACE",
        "-e", "BITBUCKET_AUTH_TOKEN",
        "markdrew/bitbucket-mcp:latest"
      ],
      "env": {
        "BITBUCKET_AUTH_TOKEN": "your-token",
        "BITBUCKET_REPO_SLUG": "your-repo",
        "BITBUCKET_WORKSPACE": "your-workspace"
      }
    }
  }
}
```

### Cursor

Add to `.cursor/mcp.json` in your project root (project-scoped) or `~/.cursor/mcp.json` (global):

```json
{
  "mcpServers": {
    "bitbucket": {
      "command": "docker",
      "args": [
        "run", "--pull=always", "--rm", "-i",
        "-e", "BITBUCKET_REPO_SLUG",
        "-e", "BITBUCKET_WORKSPACE",
        "-e", "BITBUCKET_AUTH_TOKEN",
        "markdrew/bitbucket-mcp:latest"
      ],
      "env": {
        "BITBUCKET_AUTH_TOKEN": "your-token",
        "BITBUCKET_REPO_SLUG": "your-repo",
        "BITBUCKET_WORKSPACE": "your-workspace"
      }
    }
  }
}
```

### VS Code (GitHub Copilot)

Add to `.vscode/mcp.json` in your project root (workspace) or open via the Command Palette → "MCP: Open User Configuration" (global):

```json
{
  "servers": {
    "bitbucket": {
      "command": "docker",
      "args": [
        "run", "--pull=always", "--rm", "-i",
        "-e", "BITBUCKET_REPO_SLUG",
        "-e", "BITBUCKET_WORKSPACE",
        "-e", "BITBUCKET_AUTH_TOKEN",
        "markdrew/bitbucket-mcp:latest"
      ],
      "env": {
        "BITBUCKET_AUTH_TOKEN": "your-token",
        "BITBUCKET_REPO_SLUG": "your-repo",
        "BITBUCKET_WORKSPACE": "your-workspace"
      }
    }
  }
}
```

### Warp

Add to your Warp MCP settings (Settings → MCP):

```json
{
  "bitbucket": {
    "command": "docker",
    "args": [
      "run", "--pull=always", "--rm", "-i",
      "-e", "BITBUCKET_REPO_SLUG",
      "-e", "BITBUCKET_WORKSPACE",
      "-e", "BITBUCKET_AUTH_TOKEN",
      "markdrew/bitbucket-mcp:latest"
    ],
    "env": {
      "BITBUCKET_AUTH_TOKEN": "your-token",
      "BITBUCKET_REPO_SLUG": "your-repo",
      "BITBUCKET_WORKSPACE": "your-workspace"
    }
  }
}
```

## What it exposes

The underlying module includes Bitbucket-oriented capabilities such as:

- pull request operations
- reports and annotations
- refs and tags
- pipeline-related endpoints
- release context helpers

Exact tool exposure depends on how `lucli mcp bitbucket` presents the module in your MCP client.

## Related image

If you want a general-purpose CLI/pipeline image instead of an MCP server, use [`markdrew/bitbucket-lucli`](https://hub.docker.com/r/markdrew/bitbucket-lucli).
