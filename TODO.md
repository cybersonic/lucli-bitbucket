# TODO
This file is a list of things that could be done to improve the module.

## Features

- [ ] Add License
- [ ] Add Contribution guide
- [ ] Add documentation
## Refactoring

- [ ] Split `BitbucketClient.cfc` into focused components while keeping `BitbucketClient` as a backward-compatible facade.
- [ ] Introduce `BitbucketTransport.cfc` for auth/header handling and HTTP `doCall()` logic.
- [ ] Introduce endpoint group components (starting with `BitbucketPullRequests.cfc` and `BitbucketPipelines.cfc`).
- [ ] Keep all current public method names available on `BitbucketClient` via delegation during migration.
