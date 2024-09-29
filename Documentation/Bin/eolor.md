# EOLor - End of Line Converter

*EOLor* is a POSIX shell script that converts text file line endings between CRLF (Carriage Return and Line Feed) and LF (Line Feed) formats. It allows you to seamlessly switch between different line ending formats on Unix-like systems.

## Table of Contents

- [Features](#features)
- [Usage](#usage)
- [Dependencies](#dependencies)
- [Installation](#installation)
- [License](#license)

## Features

- Converts line endings between CRLF (DOS/Windows) and LF (Unix/Linux) formats.
- Supports both single file conversion and batch conversion of files in a specified directory.
- Provides options for verbose mode, quiet mode, and test mode.
- Automatically detects the operating system to use the appropriate conversion tool.
- Handles binary files gracefully, skipping the conversion process.
- Removes any Byte Order Mark (BOM) present in files before conversion.

## Usage

```sh
EOLor [OPTIONS] <PATH>
```

### Options

- `-h`, `--help` :-            Display the condensed usage guide.
- `-v`, `--version` :-         Display the current version number.
- `-d`, `--verbose` :-         Enable verbose mode (Default).
- `-q`, `--quiet` :-           Suppress all output, including errors.
- `-c`, `--win`, `--crlf` :-   Convert to CRLF line endings.
- `-l`, `--nix`, `--lf` :-     Convert to LF line endings.
- `-t`, `--test` :-            Test mode (simulation without actual conversion).

### Examples

1. Convert files in a directory to the default line ending format based on the operating system:

    ```sh
    EOLor /path/to/directory
    ```

    By omitting the `-c` or `-l` options, the script will automatically detect the operating system and use the appropriate line ending format. On Windows, it will use CRLF, and on Unix-like systems, it will use LF.

2. Convert files of multiple paths to different line ending formats:

    ```sh
    EOLor --win /path/to/dir1 --nix /path/to/dir2 my_file.txt
    ```

    In this example, different conversion options are given for each directory, and the script will perform the following conversions accordingly:

    - All files in `/path/to/dir1` to CRLF (DOS) line endings.
    - All files in `/path/to/dir2` to LF (Unix) line endings.
    - `my_file.text` based on the operating system.

3. Convert a single file to LF line endings with verbose mode:

    ```sh
    EOLor --lf --verbose my_file.txt
    ```

    This command converts the my_file.txt file to LF line endings and displays verbose messages during the conversion.

4. Convert all files in a directory to CRLF line endings with quiet mode:

    ```sh
    EOLor --quiet --crlf /path/to/directory
    ```

    This command converts all files in the specified directory to CRLF line endings, suppressing all output, including errors.

5. Simulate the conversion of a file to CRLF line endings:

    ```sh
    EOLor --test --crlf my_file.txt
    ```

    In test mode, the script simulates the conversion of the my_file.txt file to CRLF line endings without actually making any changes. This is useful for previewing what the conversion would look like.

## Dependencies

- POSIX shell utilities (usually pre-installed on Unix-like systems).
- Optional dependencies for more efficient conversion:
  - `dos2unix`: For converting to LF (Unix to DOS).
  - `unix2dos`: For converting to CRLF (DOS to Unix).

  > Note: These optional dependencies are recommended for better performance but not required.

## Installation

1. Download the `EOLor` script to your local machine.

2. Make the script executable:

    ```sh
    chmod +x EOLor
    ```

3. Place the script in a directory that is included in your system's `PATH` environment variable to use it globally.

4. Optionally, install the `dos2unix` and `unix2dos` utilities for more efficient conversions:

    - On Windows systems:

        Ensure you have a POSIX-compatible shell environment on your Windows system. You can use tools like Cygwin or Git Bash, both of which come loaded with the necessary utilities.

    - On Debian/Ubuntu-based systems:

      ```sh
      sudo apt-get install dos2unix unix2dos
      ```

    - On Red Hat/CentOS-based systems:

      ```sh
      sudo yum install dos2unix unix2dos
      ```

## License

*EOLor* is released under the MIT License. See the [LICENSE](LICENSE) file for details.
