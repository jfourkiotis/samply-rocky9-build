# samply-rocky9-build

Builds the [`samply`](https://crates.io/crates/samply) sampling profiler on
Rocky Linux 9 via GitHub Actions, using `cargo install samply` against the
latest version published on crates.io.

## What it does

The workflow at [.github/workflows/build.yml](.github/workflows/build.yml):

1. Runs in a `rockylinux:9` container on a GitHub-hosted `ubuntu-latest` runner.
2. Installs build deps via `dnf` (gcc, openssl-devel, pkgconfig, …).
3. Installs the stable Rust toolchain with `rustup`.
4. Runs `cargo install samply --root dist` to fetch and build the latest
   published version from crates.io.
5. Uploads the resulting `samply` binary as a workflow artifact named
   `samply-rocky9-x86_64`.

## Triggers

- Every push to `main`
- Manual: `workflow_dispatch`
- Weekly cron (Monday 06:00 UTC) so the artifact tracks new releases

## Getting the binary

After a successful run, download the `samply-rocky9-x86_64` artifact from the
Actions run page. The binary is dynamically linked against Rocky 9's glibc
(2.34) and OpenSSL, so it should run on Rocky 9 / RHEL 9 / AlmaLinux 9 and any
binary-compatible distro.
