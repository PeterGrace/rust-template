//! `{{crate_name}}_core`: the application logic of `{{project-name}}`.
//!
//! The `{{project-name}}` binary only parses arguments, sets up logging and handles signals;
//! everything else lives here, so unit tests, integration tests under `tests/`, and other
//! crates can call it without spawning a process.

pub mod app;
pub mod config;
pub mod error;

// Re-exports, so callers can write `{{crate_name}}_core::Config` rather than the full path.
pub use config::{Config, LogFormat};
pub use error::{Error, Result};
