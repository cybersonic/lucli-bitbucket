# Changelog
All notable changes to the `bitbucket` LuCLI module will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## Unreleased
### Added
- Pull Request API support in `BitbucketClient.cfc`, including helpers for listing, retrieving, creating/updating PRs, merging/declining, approvals, requesting changes, diff/diffstat/patch, activity, commits, comments, tasks, default reviewers, and PRs-for-commit.
- New module subcommands that map to the Bitbucket REST API pull request endpoints (e.g. `lucli bitbucket pullrequests`, `pullrequests_get`, `pullrequests_diff`, `pullrequests_comments_create`, etc.).
- Optional CLI overrides for `workspace`, `repoSlug`, and `authToken` on PR and report-related commands.
- Backward-compatible wrappers for `createReport` and `createAnnotations`.
- Convenience behaviors for writing diff/patch content to disk via `--outputpath`.
- Decorated helper commands: `filterAnnotationsInDiff` and `downloadPRFiles`.
- Refs API support for tags via `lucli bitbucket refs_tags`.
- Decorated helper command `weeklyReleaseContext` to build a weekly merged-to-main release context (PRs + optional diffstat/commits) without a git clone.
- Reports API-style subcommands: `reports`, `reports_get`, `reports_create`, `reports_delete`, `reports_annotations`, `reports_annotations_get`, `reports_annotations_post`, `reports_annotations_create`, `reports_annotations_put`, and `reports_annotations_delete`.

### Changed
- `BitbucketClient.doCall()` now returns response content as a string (including JSON) rather than deserializing JSON into CFML structs/arrays. This keeps module output pipe-friendly (e.g. `lucli bitbucket pullrequests | jq`) until LuCLI implements a global `--format`.
- `downloadPRFiles()` now deserializes diffstat JSON internally (only where needed) so it can iterate `values` while the client remains "bare JSON".
- `BitbucketClient.doCall()` treats any 2xx response as success.
- `Module.cfc` now defaults to `showHelp()` when no `--action` is provided; legacy `--action=<publicFunctionName>` dispatch is still supported.
- `BitbucketClient.downloadFile()` forces a raw response (no JSON parsing) to ensure file downloads always write correct content.
- Legacy report wrappers are now explicitly deprecated in code comments while remaining supported for backward compatibility (`createReport`, `createAnnotations`, `postReport`, `postReportAnnotations`).
- Personal API token auth mode now validates `BITBUCKET_AUTH_USER` as an email address via `isValid("email", ...)`.
