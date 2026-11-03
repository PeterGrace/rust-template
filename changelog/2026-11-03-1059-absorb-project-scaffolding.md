# 2026-11-03 10:59 EST: Absorb the scaffolding later projects converged on

## Summary

Projects started from this template (bolt_deployment_controller, github_webhook_exporter,
infiniroute, sitewalk, autobots) each rebuilt the same scaffolding by hand: a justfile that CI
calls, `[lints]`, `rust-toolchain.toml`, `cargo-deny`, signal handling with `tokio::signal`,
env-based configuration, a distroless Dockerfile, Hegel and dylint. The template now ships
that, as a Cargo workspace, and fixes the bugs the projects each had to fix. The optional
pieces are cargo-generate questions.

## Changed

- Fixed: `dotenv` (unmaintained) replaced by `dotenvy`, which CLAUDE.md already required.
  `console-subscriber` no longer starts unconditionally (it bound port 6669, so a second
  process panicked); it is the binary's `tokio-console` feature, and `--cfg tokio_unstable`
  moved from `.cargo/config.toml` into `just run-tokio-console` / `clippy-tokio-console`.
  `.gitignore` now ignores `.env`. The CLAUDE.md link to `docs/reference/doc-comment-example.md`
  resolves (it is relative to `.claude/`). Typo "adnd". Dropped `ctrlc` and `lazy_static`.
- Layout: a virtual workspace (`resolver = "3"`, edition 2024, `rust-version = "1.88"`) with
  `crates/{{project-name}}` (thin binary: clap, `.env`, tracing, signals, bounded drain,
  `main() -> ExitCode`) and `crates/{{project-name}}-core` (library: `config.rs` with an
  injectable env lookup that reports every invalid variable, `error.rs` with one `thiserror`
  enum, `app.rs` the main task stopped through a `watch` channel).
- `[workspace.lints]` (`missing_docs`, `unsafe_code = "forbid"`, clippy `unwrap_used`,
  `dbg_macro`, `todo`), `[profile.release]` with LTO, `rust-toolchain.toml` pinned to 1.99.1.
- `justfile`: `fmt`, `fmt-check`, `clippy`, `lint`, `test`, `doc`, `deny`, `coverage`,
  `coverage-markdown`, `msrv`, `gate`, `run`, `run-tokio-console`, plus the optional recipes.
  It uses shell variables, not just's `{{ }}`, so Liquid can render it.
- `deny.toml`, `.env.example`, `AGENTS.md` (a pointer to `.claude/`), `README.md` and
  `docs/superpowers/{specs,plans}/`. `cargo-generate.toml` ignores this template's own
  `changelog/` (its `ignore` takes exact paths, not globs), so a generated project creates
  `changelog/` with its first entry.
- `cargo-generate.toml` questions: `ci` (`github`, `forgejo` or `none`), `docker`, `hegel`,
  `dylint`, `release`, `claims`; each drops its files when declined. GitHub CI runs each check
  as a job with SHA-pinned actions and Dependabot, and pushes images to GHCR on `v*` tags.
  Forgejo CI runs in `r.gfpd.us/gfd/ci-runner` and pushes to Harbor. With `hegel`, tests are
  property tests and `just hegel-canary` proves cases run; with `dylint`, trailofbits
  `supplementary` runs (and `hyp_hegel` too when `hegel` is on). `release` adds cargo-release
  with `release-prepare.sh` / `release-ship.sh`.
- `.claude/CLAUDE.md`: the changelog file format (this file's), a Project Layout section, the
  Hegel rule when chosen, `#[expect]` over `#[allow]`, and `just gate` as the pre-commit
  checklist. Rule globs became `**/src/...` so they match inside `crates/*`.

## Tests

Generated four variants with `cargo generate --path`: `full` (GitHub, every option),
`lean` (no CI, no options), `fjo` (Forgejo, Docker, Hegel, release) and `fjo2` (Forgejo,
Hegel, dylint, claims).

- `just gate` passed on all four, dylint included on `full` and `fjo2`. On `full`,
  `just clippy-tokio-console`, `just deny`, `just msrv` (1.88), `just coverage` (70% of lines)
  with `just coverage-markdown`, and `just image-build` also passed.
- A plain `#[test]` added to `full` failed `just dylint` ("test does not use the hegel
  property-testing framework"), so the `hyp_hegel` run is not vacuous.
- The image (40.9 MB) prints `--version`, and `docker stop` (SIGTERM) logs the shutdown and
  exits 0.
- A fresh project has no `Cargo.lock`, so the dev recipes do not pass `--locked`; CI checks
  the lockfile once with `cargo fetch --locked`, and `deny` and `msrv` keep `--locked`.
- The binary prints `--help`, logs an invalid configuration as one error listing both bad
  variables and exits 1; `tests/startup.rs` starts it and stops it with SIGTERM and SIGINT.
- The rendered workflows and dependabot config parse as YAML, the TOML files parse, and no
  Liquid tags are left in the output.

## Not done

- The Forgejo workflow does not run coverage or MSRV: the shared `ci-runner` image may lack
  `cargo-llvm-cov` and extra toolchains.
- Helm/kustomize manifests, OTLP telemetry, metrics and health endpoints stay in the projects
  that need them.
