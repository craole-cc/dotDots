#!/usr/bin/env rust-script
//! ```cargo
//! [dependencies]
//! clap = { version = "4.5.1", features = ["derive"] }
//! colored = "2.0"
//! similar = "2.4"
//! tempfile = "3.10"
//! time = { version = "0.3", features = ["formatting", "macros"] }
//! ```

use clap::{Parser, ValueEnum};
use colored::*;
use diff::{Diff, Result as DiffResult};
use std::{
  fs,
  io::{self, Write},
  path::{Path, PathBuf},
  process,
};
use tempfile::NamedTempFile;
use time::{OffsetDateTime, format_description::FormatItem, macros::format_description};

/// EditorConfig file formatter and linter
///
/// Formats and validates .editorconfig files according to standardized rules.
/// Supports both checking and formatting modes with configurable options.
#[derive(Parser, Debug)]
#[command(version, about)]
struct Args {
  /// Files to process
  #[arg(required = true)]
  files: Vec<PathBuf>,

  /// Operation mode
  #[arg(short, long, value_enum, default_value_t = Mode::Format)]
  mode: Mode,

  /// Enable debug output
  #[arg(short, long)]
  debug: bool,

  /// Formatting options
  #[command(flatten)]
  format_opts: FormatOptions,
}

#[derive(Copy, Clone, Debug, PartialEq, Eq, ValueEnum)]
enum Mode {
  /// Check files without modifying
  Check,
  /// Format files in place
  Format,
}

#[derive(Parser, Debug)]
struct FormatOptions {
  /// Enable section separation
  #[arg(short = 's', long, default_value_t = true)]
  separate_sections: bool,

  /// Enable leading whitespace trimming
  #[arg(short = 'l', long, default_value_t = true)]
  trim_leading: bool,

  /// Enable trailing whitespace trimming
  #[arg(short = 't', long, default_value_t = true)]
  trim_trailing: bool,

  /// Enable multiple space squeezing
  #[arg(short = 'w', long, default_value_t = true)]
  squeeze_whitespace: bool,

  /// Enable blank line removal
  #[arg(short = 'b', long, default_value_t = true)]
  remove_blank_lines: bool,
}

#[derive(Debug)]
struct FileInfo {
  path: PathBuf,
  modified: OffsetDateTime,
}

impl FileInfo {
  fn new(path: PathBuf) -> io::Result<Self> {
    let metadata = fs::metadata(&path)?;
    let modified = OffsetDateTime::from(metadata.modified()?);
    Ok(Self { path, modified })
  }

  fn format_modified(&self) -> String {
    static FORMAT: &[FormatItem] = format_description!("[year]-[month]-[day] [hour]:[minute]");
    self.modified.format(&FORMAT).unwrap_or_default()
  }
}

/// Core formatter implementation
struct Formatter {
  opts: FormatOptions,
  debug: bool,
}

impl Formatter {
  fn new(opts: FormatOptions, debug: bool) -> Self {
    Self { opts, debug }
  }

  fn process_file(&self, path: &Path, mode: Mode) -> io::Result<bool> {
    // Get file info for debugging
    if self.debug {
      let info = FileInfo::new(path.to_path_buf())?;
      println!(
        "Processing: {} (modified: {})",
        info.path.display(),
        info.format_modified()
      );
    }

    // Read input file
    let input = fs::read_to_string(path)?;

    // Format content
    let output = self.format_content(&input);

    // Check if changes needed
    if input == output {
      return Ok(false);
    }

    // Show diff
    self.show_diff(&input, &output);

    // Apply changes in format mode
    if mode == Mode::Format {
      let mut temp = NamedTempFile::new()?;
      temp.write_all(output.as_bytes())?;
      temp.persist(path)?;
    }

    Ok(true)
  }

  fn format_content(&self, content: &str) -> String {
    let mut lines: Vec<String> = content.lines().map(String::from).collect();

    // Apply formatting rules
    if self.opts.trim_leading {
      lines
        .iter_mut()
        .for_each(|line| *line = line.trim_start().to_string());
    }
    if self.opts.trim_trailing {
      lines
        .iter_mut()
        .for_each(|line| *line = line.trim_end().to_string());
    }
    if self.opts.squeeze_whitespace {
      lines
        .iter_mut()
        .for_each(|line| *line = line.split_whitespace().collect::<Vec<_>>().join(" "));
    }
    if self.opts.remove_blank_lines {
      lines.retain(|line| !line.trim().is_empty());
    }
    if self.opts.separate_sections {
      // Add blank lines before sections
      let mut i = 0;
      while i < lines.len() {
        if lines[i].starts_with('[') && i > 0 {
          lines.insert(i, String::new());
          i += 2;
        } else {
          i += 1;
        }
      }
    }

    lines.join("\n") + "\n"
  }

  fn show_diff(&self, old: &str, new: &str) {
    let diff = Diff::new(old, new);
    for change in diff.iter_changes() {
      match change {
        DiffResult::Left(l) => println!("{}", format!("-{}", l).red()),
        DiffResult::Right(r) => {
          println!("{}", format!("+{}", r).green())
        }
        DiffResult::Both(b, _) => println!(" {}", b),
      }
    }
  }
}

fn run() -> io::Result<i32> {
  // Parse command line arguments
  let args = Args::parse();

  // Create formatter
  let formatter = Formatter::new(args.format_opts, args.debug);

  // Process all files
  let mut exit_code = 0;
  for file in args.files {
    match formatter.process_file(&file, args.mode) {
      Ok(true) => {
        if args.mode == Mode::Check {
          eprintln!("Formatting issues found: {}", file.display());
          exit_code = 1;
        }
      }
      Ok(false) => {
        if args.debug {
          println!("No changes needed: {}", file.display());
        }
      }
      Err(e) => {
        eprintln!("Error processing {}: {}", file.display(), e);
        exit_code = 2;
      }
    }
  }

  Ok(exit_code)
}

fn main() {
  process::exit(match run() {
    Ok(code) => code,
    Err(e) => {
      eprintln!("Error: {}", e);
      2
    }
  });
}
