# syntax=docker/dockerfile:1.7
#
# Builds `{{project-name}}` into a distroless image that runs as a non-root user.
#
# cargo-chef caches the dependency build in its own layer: `planner` reduces the workspace to
# a recipe of its dependencies, `builder` compiles that recipe (cached until Cargo.toml or
# Cargo.lock change), then compiles the workspace's own code. Base images are pinned by digest;
# the `rust` tag matches rust-toolchain.toml, so bump both together.

FROM docker.io/library/rust:1.99.1-bookworm@sha256:9181b56c2a21ab1d5e73cffe04fc762426d30aa7fac3c91141dd033f49a7fc8b AS chef
WORKDIR /build
RUN --mount=type=cache,target=/usr/local/cargo/registry,sharing=locked \
    cargo install cargo-chef --version 0.1.78 --locked

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /build/recipe.json recipe.json
RUN --mount=type=cache,target=/usr/local/cargo/registry,sharing=locked \
    cargo chef cook --release --locked --recipe-path recipe.json
COPY . .
RUN --mount=type=cache,target=/usr/local/cargo/registry,sharing=locked \
    cargo build --release --locked -p {{project-name}}

# File times from SOURCE_DATE_EPOCH, so the same source builds the same image.
ARG SOURCE_DATE_EPOCH=0
RUN install -D -m 0555 target/release/{{project-name}} /out/usr/local/bin/{{project-name}} \
    && find /out -exec touch --no-dereference --date="@${SOURCE_DATE_EPOCH}" -- {} +

# `cc` carries glibc and libgcc, which a default (non-musl) Rust binary links against.
FROM gcr.io/distroless/cc-debian12:nonroot@sha256:9dac0a79194e45a7da0158a9c6da57b217585af0786db3845d1f0ec1a0dd182f
COPY --from=builder /out/ /
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/{{project-name}}"]
