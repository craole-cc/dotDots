#!/usr/bin/env rust-script
//! ```cargo
//! [dependencies]
//! ```

// Script configuration
const SCR_NAME: &str = "is_graphical_env";
const SCR_DESCRIPTION: &str = "Validate graphical environment";
const SCR_VERSION: &str = "1.0";
const PADDING: &str = "  ";

// Global variables
let mut flag_VERBOSE: bool = false;

// Parse command-line options
fn parse_cli(args: &[String]) {
    if let Some(arg) = args.get(1) {
        match arg.as_str() {
            "-h" | "--help" => post_info("--help"),
            "-v" | "--version" => post_info("--version"),
            "-d" | "--verbose" => flag_VERBOSE = true,
            _ => {
                if !arg.is_empty() {
                    pout("--option", arg);
                }
            }
        }
    }
}

// Print help and usage information
fn post_info(option: &str) {
    match option {
        "--help" => {
            println!("Usage:");
            println!("{}{} [OPTIONS]", PADDING, SCR_NAME);
            println!("\nDescription:");
            println!("{}{}", PADDING, SCR_DESCRIPTION);
            println!("\nOptions:");
            println!("{}-h, --help     Usage guide", PADDING);
            println!("{}-v, --version  Script version", PADDING);
            println!("{}-d, --verbose  Environment details", PADDING);
        }
        "--version" => {
            println!("{}", SCR_VERSION);
        }
        "--error" => {
            let error_message = std::env::args().nth(2);
            if let Some(message) = error_message {
                println!("Error:\n{}{}", PADDING, message);
            }
        }
        _ => {
            if flag_VERBOSE {
                let environment = get_environment();
                let protocol = get_protocol();
                println!("A {} environment via {}", environment, protocol);
            }
        }
    }
}

// Print errors and usage info
fn pout(option: &str, message: &str) {
    match option {
        "--option" => {
            post_info("--error");
            post_info("--help");
        }
        _ => {}
    }
    pull_out(1);
}

// Trigger early exit
fn pull_out(exit_code: i32) {
    std::process::exit(exit_code);
}

// Check for the presence of a graphical environment
fn process() {
    let environment = get_environment();
    let protocol = get_protocol();

    if protocol.is_empty() {
        post_info("--error", "Unknown environment");
        post_info("--help");
    } else {
        post_info("--");
    }
}

// Get the environment type
fn get_environment() -> &'static str {
    if let Ok(session_type) = std::env::var("XDG_SESSION_TYPE") {
        if session_type == "tty" {
            return "non-graphical TTY";
        }
    }

    if let Some(display) = std::env::var("WAYLAND_DISPLAY").ok().or_else(|| std::env::var("DISPLAY").ok()) {
        if !display.is_empty() {
            return "graphical Unix";
        }
    }

    if std::env::consts::OS == "windows" {
        return "graphical Windows";
    }

    "graphical"
}

// Get the protocol
fn get_protocol() -> &'static str {
    if let Ok(session_type) = std::env::var("XDG_SESSION_TYPE") {
        if session_type == "tty" {
            return std::env::var("TTY").unwrap_or_default().as_str();
        }
    }

    if let Some(display) = std::env::var("WAYLAND_DISPLAY").ok() {
        if !display.is_empty() {
            return "Wayland";
        }
    }

    if let Some(display) = std::env::var("DISPLAY").ok() {
        if !display.is_empty() {
            return "X11";
        }
    }

    if cfg!(target_os = "windows") {
        return std::env::consts::OS;
    }

    std::env::var("TERM").unwrap_or_default().as_str()
}

fn main() {
    // let args: Vec<String> = std::env::args().collect();
    // parse_cli(&args);
    // process();
    // pull_out(0);
}
