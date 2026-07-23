# markdrew/bitbucket-lucli

LuCLI image with the `bitbucket` module preinstalled.

This image is intended for CI/CD, Bitbucket Pipelines, GitHub Actions, and local automation where you want to run `lucli bitbucket ...` commands without installing the module at runtime.

## What this image is for

Use this image when you want a container that starts with the Bitbucket LuCLI module ready to use.

Typical use cases include:

- creating reports and annotations
- fetching pull request diffs
- listing tags and refs
- gathering release context
- running Bitbucket-related automation in pipelines

The image is built from the same source as the MCP image, but this variant is optimized for direct CLI and pipeline usage.

## Tags

- `latest` — stable release image
- `snapshot` — current development build

## Authentication

By default, the module expects `BITBUCKET_AUTH_TOKEN` and uses Bearer auth.

If you also set `BITBUCKET_AUTH_USER`, the module treats `BITBUCKET_AUTH_TOKEN` as a personal API token and uses Basic auth instead.

Common environment variables:

- `BITBUCKET_WORKSPACE`
- `BITBUCKET_REPO_SLUG`
- `BITBUCKET_AUTH_TOKEN`
- `BITBUCKET_AUTH_USER` (optional, for personal API token mode)

## Usage

List tags:

```bash
docker run --rm \
  -e BITBUCKET_WORKSPACE=your-workspace \
  -e BITBUCKET_REPO_SLUG=your-repo \
  -e BITBUCKET_AUTH_TOKEN=your-token \
  markdrew/bitbucket-lucli:latest \
  refs_tags q='name~"revision-"'
```

Get a pull request diff and write it to a file in a mounted workspace:

```bash
docker run --rm \
  -v "$PWD:/workspace" \
  -w /workspace \
  -e BITBUCKET_WORKSPACE=your-workspace \
  -e BITBUCKET_REPO_SLUG=your-repo \
  -e BITBUCKET_AUTH_TOKEN=your-token \
  markdrew/bitbucket-lucli:latest \
  pullrequests_diff pullRequestId=123 outputPath=diff.txt
```

Build weekly release context:

```bash
docker run --rm \
  -e BITBUCKET_WORKSPACE=your-workspace \
  -e BITBUCKET_REPO_SLUG=your-repo \
  -e BITBUCKET_AUTH_TOKEN=your-token \
  markdrew/bitbucket-lucli:latest \
  weeklyReleaseContext \
  branch=main \
  sinceISO=2026-03-01T00:00:00Z \
  untilISO=2026-03-08T00:00:00Z \
  includeDiffstat=true \
  includeDiff=false \
  includeCommits=false
```

## Related image

If you want to run this module as an MCP server instead of a CLI/pipeline container, use [`markdrew/bitbucket-mcp`](https://hub.docker.com/r/markdrew/bitbucket-mcp).
