# Project Rules (LuCLI bitbucket module)
These rules are for working on the `bitbucket` LuCLI module.

## Goals
- Keep module commands closely aligned with Bitbucket Cloud REST API endpoint groups.
- Keep all public module functions returning *native* CFML values (struct/array/string) — avoid printing from inside commands.
- Preserve backwards compatibility for existing commands.

## Command / naming strategy
- One **public function** in `Module.cfc` = one `lucli bitbucket <subcommand>`.
- Prefer command names that match Bitbucket API groups:
  - `pullrequests` (for `/pullrequests`)
  - Future groups should follow the same pattern (e.g. `commits`, `pipelines`, `repositories`, etc.).
- For nested endpoints, use underscore names that stay readable:
  - `pullrequests_get`, `pullrequests_create`, `pullrequests_comments_create`, `pullrequests_tasks_delete`, etc.
- “Decorated”/helper commands that are not 1:1 REST endpoints (filtering, downloads, formatting) should be clearly documented in the function hint / comment and highlighted in the changelog.

## Adding a new Bitbucket endpoint (standard workflow)
When implementing a new REST endpoint:
1. Add a method to `BitbucketClient.cfc`.
   - Keep method names descriptive and consistent with existing ones.
   - Build the path under `repositories/#variables.workspace#/#variables.repoSlug#/...`.
   - Call `doCall(path=..., method=..., data=...)`.
   - Return the result of `doCall()` (which will already be a native CFML value).
2. Add a **public** wrapper function to `Module.cfc`.
   - The wrapper should:
     - accept optional `workspace`, `repoSlug`, `authToken` overrides
     - create a client via `createClient(workspace=..., repoSlug=..., authToken=...)`
     - forward arguments to the client method
     - return the native result
3. If the endpoint needs a JSON body:
   - accept `dataFile` and parse it via `readJsonFile(dataFile)` (do not inline JSON strings).
4. If the endpoint returns large text (diff/patch) and it’s useful:
   - add optional `outputPath` and write the returned string to disk.
5. Update `CHANGELOG.md` under **Unreleased**.

## Required overrides (workspace/repo)
- Every new public command wrapper should accept:
  - `string workspace=""`
  - `string repoSlug=""`
  - `string authToken=""`
- The wrapper must pass these to `createClient(...)`.

## Return format rules
- `BitbucketClient.doCall()` returns:
  - struct/array for JSON responses
  - string for non-JSON responses
- Module commands must return those native values.
- Avoid calling `out()` / `systemOutput()` inside public commands.
  - If output is needed, do it at a higher orchestration layer (or keep it as a separate helper that’s explicitly “decorated”).

## Main entrypoint rules
- `Module.main()` should primarily return `showHelp()`.
- Backward compatibility: `Module.main(action=...)` may dispatch to an existing **public** function (legacy `--action=<name>` usage).
- `main()` should not contain a large switch statement.

## Backward compatibility
- Do not remove/rename existing public commands without providing an alias wrapper.
- Keep existing “legacy” functions working (`createReport`, `createAnnotations`, etc.).



## Testing 
- Always write a test before implementing a new feature.
- Tests should be written in the `tests/specs` directory.
- Tests should be named like `<feature_name>Spec.cfc`.
- Tests should be written using the `testbox` framework.
- Tests can be run directly by starting the server using `lucli server start` and then running `http://localhost:8001/tests/`
- Mocking is supported by using the `testbox` framework.

## Footguns / notes
- Do not use the variable name `client` in CFML code.
  - `client` is a built-in CFML scope (client storage). In some runtimes it may be disabled, and references like `client.foo` will error.
  - Prefer names like `bb`, `bbClient`, or `api`.
- If downloading files, ensure we get raw content:
  - `BitbucketClient.downloadFile()` uses `doCall(..., parseResponse=false)`.
