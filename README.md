     
# bitbucket

A LuCLI module that connects to bitbucket.

It is desgined to run within a bitbucket pipeline using the environment variables provided by bitbucket. You can override these variables by passing them as arguments to the module.

## Usage

```bash
# submit a report to bitbucket (it uses a json with annotations to also submit the annotations)
lucli bitbucket createReport commit=$BITBUCKET_COMMIT file=report.json

# Looks for the annotations in the report under the `annotations`
lucli bitbucket createAnnotations commit=$BITBUCKET_COMMIT reportId=my_report file=report.json

# Get the diff for a pull request (used with filterAnnotationsInDiff)
lucli bitbucket pullrequests_diff pullRequestId=123 outputPath=diff.txt

# Return only the annotations that are in the diff
lucli bitbucket filterAnnotationsInDiff reportPath=report.json diffFilePath=diff.txt

# Weekly release context (no git clone required)
# Produces JSON suitable to send to Oz/Warp for summarization.
lucli bitbucket weeklyReleaseContext \
  branch=main \
  sinceISO=2026-03-01T00:00:00Z \
  untilISO=2026-03-08T00:00:00Z \
  includeDiffstat=true \
  includeDiff=false \
  includeCommits=false

# List tags (useful if you later want to key off revision-* tags)
lucli bitbucket refs_tags q='name~"revision-"'
```

## Description

This module is aimed to be used at creating reports and annotations in Bitbucket pull requests. It can create reports with annotations based on a JSON report file, fetch pull request diffs, and filter annotations to only those that are relevant to the changes in the pull request.

It works well with the lucli-lint module, since the lucli-lint module can generate reports with annotations in the required format.

## Authentication

By default the module expects `BITBUCKET_AUTH_TOKEN` and sends it as a Bearer token.

If `BITBUCKET_AUTH_USER` is set, the module treats `BITBUCKET_AUTH_TOKEN` as a personal API token and sends Basic auth (`BITBUCKET_AUTH_USER:BITBUCKET_AUTH_TOKEN`).

Examples:

```bash
# Bearer token mode (existing behavior)
export BITBUCKET_AUTH_TOKEN=...

# Personal API token mode (auto-switch to Basic auth)
export BITBUCKET_AUTH_USER=you@example.com
export BITBUCKET_AUTH_TOKEN=...
```

## Docker images

This repository can build two container variants from the same source:

- `markdrew/bitbucket-lucli:{latest,snapshot}` for general LuCLI and pipeline usage
- `markdrew/bitbucket-mcp:{latest,snapshot}` for MCP usage via `lucli mcp bitbucket`

Both images copy this module directly into LuCLI's modules directory inside the container instead of installing from a registry.

At the moment, GitHub Actions is set up to build and validate these images only. Publishing/pushing can be enabled later once the naming and runtime behavior are settled.

During CI container builds, `module.json` can be stamped with a build/release version for the image contents without committing that version change back to the repository.

