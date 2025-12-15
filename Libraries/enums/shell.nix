{_, ...}: let
  mkVal = _.mkCaseInsensitiveListValidator;
in {
  /**
  Shells - command-line shell options.

  Available interactive shells for user sessions and scripting.

  # Shells
  - bash: Bourne Again SHell (default on most systems, POSIX-compatible)
  - zsh: Z Shell (extended Bourne shell, powerful completion)
  - fish: Friendly Interactive SHell (user-friendly, modern syntax)
  - nushell: Modern structured data shell (typed, table-oriented)
  - pwsh: PowerShell Core (cross-platform, object-oriented)
  - powershell: Alias for pwsh

  # Structure
  ```nix
  {
    values = [ "bash" "zsh" "fish" "nushell" ... ];
    validator = { check, list };
  }
  ```

  # Usage
  ```nix
  # Validate shell selection
  _lib.shells.validator.check { name = "ZSH"; }  # => true

  # Check if shell is POSIX-compatible
  _lib.inList config.shell ["bash" "sh"]

  # List all available shells
  _lib.shells.values
  ```
  */
  shells = let
    values = [
      "bash"
      "zsh"
      "fish"
      "nushell"
      "pwsh"
      "powershell"
    ];
  in {
    inherit values;
    validator = mkVal values;
  };
}
