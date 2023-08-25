# Email Validation Script

This is a simple command-line script written in Rust that validates email addresses. The script utilizes the `clap` crate for parsing command-line arguments.

## Prerequisites

- `rust-script`: The script relies on `rust-script` to run without requiring a full Rust installation. You can install `rust-script` by following the instructions at [rust-script](https://github.com/fornwall/rust-script).

## Usage

```shell
rust-script validate_email_address -h
```

```shell
Usage: validate_email_address [OPTIONS] <EMAIL>

OPTIONS:
    -h, --help      Display this help message
    -d, --verbose   Enable verbose output
    -t, --test      Perform tests on various email scenarios

EMAIL:
    Email address to validate
```

## Installation

1. Install `rust-script` using the instructions provided in the prerequisites section.

2. Copy the contents of the `validate_email_address` script into a new file called `validate_email_address`.

3. Make the script executable:

   ```shell
   chmod +x validate_email_address
   ```

4. Run the script:

   ```shell
   ./validate_email_address [OPTIONS] <EMAIL>
   ```

## Command-line Arguments

- `<EMAIL>`: The email address to validate.

- `-d, --verbose`: Enable verbose output. The script will print detailed information during email validation if this flag is provided.

- `-t, --test`: Perform tests on various email scenarios. The script will validate a set of predefined test email addresses and display the results.

## Examples

1. Validate a single email address:

   ```shell
   ./validate_email_address --verbose john.doe@example.com
   ```

   Output:

   ```stdout
   Email is valid.
   ```

2. Perform tests on various email scenarios:

   ```shell
   ./validate_email_address --test
   ```

   Output:

   ```stdout
   Validating email: missingdomain@
   Error: Email is missing the domain.

   Validating email: @missingusername.com
   Error: Email is missing the username.

   Validating email: invalidemail
   Error: Email is missing the @ sign.

   Validating email: missing@dotcom
   Error: Email is missing the domain.

   Validating email: incomplete@domain.
   Error: Email is missing the extension.

   Validating email: invalid@extensionchars.#$%com
   Error: Email has an invalid domain extension.

   Validating email: valid@domain.subdomain.tld
   Email is valid.

   Validating email: valid@example.com
   Email is valid.
   ```

## License

This script is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
