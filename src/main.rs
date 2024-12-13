#[macro_use] extern crate tracing;

use tracing_subscriber::EnvFilter;
fn main() {

    let filter_layer =
        EnvFilter::try_from_default_env().or_else(|_| EnvFilter::try_new("warn")).unwrap();
    tracing_subscriber::fmt()
        .with_env_filter(filter_layer)
        .with_file(true)
        .with_line_number(true)
        .init();

    info!("Hello, world!");
}
