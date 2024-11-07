#!/usr/bin/env rust-script
//! ```cargo
//! [dependencies]
//! clap = "2.33.0"
//! walkdir = "2.3.3"
//! prettytable = "0.10.0"
//! ```

extern crate clap;
extern crate prettytable;
extern crate walkdir;

use clap::{App, Arg};
use prettytable::{row, Table};
use std::error::Error;
use std::fs::File;
use std::io::{Read, Write};
use std::path::Path;
use walkdir::WalkDir;

fn convert_to_lf(file_path: &str) -> Result<(), Box<dyn Error>> {
    let path = Path::new(file_path);
    let mut file = File::open(path)?;
    let mut contents = String::new();
    file.read_to_string(&mut contents)?;

    let lf_contents = contents.replace("\r\n", "\n");

    let mut output_file = File::create(path)?;
    output_file.write_all(lf_contents.as_bytes())?;

    Ok(())
}

fn convert_to_crlf(file_path: &str) -> Result<(), Box<dyn Error>> {
    let path = Path::new(file_path);
    let mut file = File::open(path)?;
    let mut contents = String::new();
    file.read_to_string(&mut contents)?;

    let crlf_contents = contents.replace("\n", "\r\n");

    let mut output_file = File::create(path)?;
    output_file.write_all(crlf_contents.as_bytes())?;

    Ok(())
}

fn convert_files_in_folder(folder_path: &str, conversion_type: &str) -> Result<(), Box<dyn Error>> {
    let mut table = Table::new();
    table.add_row(row![bFg => "File", "Conversion"]);

    let walker = WalkDir::new(folder_path).into_iter();

    for entry in walker {
        let entry = entry?;
        if entry.file_type().is_file() {
            let file_path = entry.path().to_str().unwrap();
            match conversion_type {
                "lf" => {
                    convert_to_lf(file_path)?;
                    table.add_row(row![file_path, "CRLF to LF"]);
                }
                "crlf" => {
                    convert_to_crlf(file_path)?;
                    table.add_row(row![file_path, "LF to CRLF"]);
                }
                _ => println!("Invalid conversion type."),
            }
        }
    }

    if table.len() > 1 {
        table.printstd();
        println!(
            "Conversion of {} file(s) in the folder completed.",
            table.len() - 1
        );
    } else {
        println!("No files found in the folder.");
    }

    Ok(())
}

fn main() -> Result<(), Box<dyn Error>> {
    let matches = App::new("Line Ending Converter")
        .arg(
            Arg::with_name("conversion_type")
                .required(true)
                .possible_values(&["lf", "crlf"])
                .help("The type of line ending conversion"),
        )
        .arg(
            Arg::with_name("path")
                .required(true)
                .help("The path to the file or folder"),
        )
        .get_matches();

    let conversion_type = matches.value_of("conversion_type").unwrap();
    let path = matches.value_of("path").unwrap();

    if Path::new(path).is_file() {
        match conversion_type {
            "lf" => {
                convert_to_lf(path)?;
                println!("Conversion from CRLF to LF format completed.");
                println!("Converted file: {}", path);
            }
            "crlf" => {
                convert_to_crlf(path)?;
                println!("Conversion from LF to CRLF format completed.");
                println!("Converted file: {}", path);
            }
            _ => println!("Invalid conversion type."),
        }
    } else if Path::new(path).is_dir() {
        convert_files_in_folder(path, conversion_type)?;
    } else {
        println!("Invalid file or folder path.");
    }

    Ok(())
}
