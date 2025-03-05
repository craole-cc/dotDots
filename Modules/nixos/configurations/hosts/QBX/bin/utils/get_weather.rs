#!/usr/bin/env rust-script
//! ```cargo
//! [dependencies]
//! reqwest = { version = "0.11", features = ["blocking"] }
//! url = "2.5.0"
//! clap = { version = "4.4", features = ["derive"] }
//! ```

use clap::Parser;
use reqwest::blocking::Client;
use std::process;
use url::form_urlencoded;

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// Location to
    /// fetch weather
    /// for
    #[arg(default_value = "Mandeville,Jamaica")]
    location: String,

    /// Weather format (1-4)
    #[arg(long, default_value_t = 4, value_parser = clap::value_parser!(u8).range(1..=4))]
    format: u8,

    /// Enable debug output
    #[arg(long)]
    debug: bool,
}

fn fetch_weather(
    location: &str,
    format: u8,
    debug: bool,
) -> Result<String, Box<dyn std::error::Error>> {
    // Encode location for URL
    let encoded_location = form_urlencoded::Serializer::new(String::new())
        .append_key_only(location)
        .finish();

    if debug {
        eprintln!("Fetching weather for: {}", location);
    }

    let client = Client::new();
    let url = format!("https://wttr.in/{}?format={}", encoded_location, format);

    let response = client.get(&url).send()?.text()?;

    Ok(response.trim().to_string())
}

fn main() {
    let args = Args::parse();

    match fetch_weather(&args.location, args.format, args.debug) {
        Ok(weather) => {
            println!("{}", weather);
            process::exit(0);
        }
        Err(e) => {
            eprintln!("Error fetching weather: {}", e);
            process::exit(1);
        }
    }
}
