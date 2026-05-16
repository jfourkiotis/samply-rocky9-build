# samply-rocky9-build

Builds the [`samply`](https://crates.io/crates/samply) sampling profiler **and**
a self-hosted copy of the [Firefox Profiler](https://github.com/firefox-devtools/profiler)
frontend, packaged together so they can be used on an **air-gapped Rocky Linux 9**
host with no `profiler.firefox.com` access.

## What the CI produces

The workflow at [.github/workflows/build.yml](.github/workflows/build.yml) runs
three jobs:

1. **build-samply** — `rockylinux:9` container, installs Rust via `rustup`, runs
   `cargo install samply` against the latest version on crates.io.
2. **build-profiler-frontend** — `node:20-bullseye` container, clones
   `firefox-devtools/profiler` at the commit pinned in `PROFILER_REF` (env var
   in the workflow), runs `yarn install && yarn build-prod` to produce the
   static `dist/`.
3. **bundle** — combines the two into a single artifact
   `samply-rocky9-bundle.tar.gz` with this layout:

   ```
   bin/samply              # the profiler binary
   profiler-dist/          # static HTML/JS/CSS for the viewer
   serve.sh                # tiny `python3 -m http.server` wrapper
   README.md               # this file
   ```

## Triggers

- Every push to `main`
- Manual: `workflow_dispatch`
- Weekly cron (Monday 06:00 UTC) so the bundle tracks new samply releases

## Using the bundle on an air-gapped Rocky 9 box

```bash
tar xzf samply-rocky9-bundle.tar.gz -C ~/samply-bundle
cd ~/samply-bundle

# Terminal 1: serve the profiler UI locally (needs python3)
./serve.sh                       # listens on 127.0.0.1:4242

# Terminal 2: record or load a profile, pointing samply at the local UI
PROFILER_URL=http://127.0.0.1:4242 ./bin/samply record ./my-program
# ...or load a previously-captured profile:
PROFILER_URL=http://127.0.0.1:4242 ./bin/samply load profile.json.gz
```

`samply` reads `PROFILER_URL` from the environment and uses it as the origin
for the viewer page (see [samply/src/server.rs](https://github.com/mstange/samply/blob/main/samply/src/server.rs)
— falls back to `https://profiler.firefox.com` if unset). Profile data itself
never leaves the host: samply runs a local HTTP server that the viewer page
fetches the JSON from.

### Caveats for air-gapped use

The Firefox Profiler frontend may still try to fetch a few things at runtime
(Mozilla symbol server, source views, sometimes fonts). On a host with no
egress those requests will simply fail, and:

- Loading and viewing profiles works.
- Symbol resolution falls back to whatever samply itself can resolve locally
  (samply ships its own symbolication endpoint at `PATH_PREFIX/symbolicate/v5`).
- Fetching source code for stack frames from upstream Mozilla repos won't work.

## Bumping pinned versions

- **samply**: nothing to do — `cargo install samply` always pulls the latest
  from crates.io. The weekly cron picks up new releases.
- **Firefox Profiler frontend**: edit the `PROFILER_REF` env var at the top of
  [.github/workflows/build.yml](.github/workflows/build.yml) and commit.

## Getting the bundle

### Preferred: download from a GitHub Release

Releases are served from `objects.githubusercontent.com`, which most corporate
firewalls allow by default (unlike Actions artifacts, which redirect to
`*.blob.core.windows.net` and are commonly blocked).

```
https://github.com/jfourkiotis/samply-rocky9-build/releases/latest
```

The `samply-rocky9-bundle.tar.gz` asset is attached to each release.

### Cutting a new release

Push a tag matching `v*`:

```
git tag v0.1.0
git push origin v0.1.0
```

The workflow's `release` job runs on tag push, rebuilds the bundle, and
publishes a release with auto-generated notes and the tarball attached.

### Fallback: workflow artifact (requires GitHub login + Azure Blob reachable)

```
gh run list --workflow build.yml
gh run download <run-id> -n samply-rocky9-bundle
```
