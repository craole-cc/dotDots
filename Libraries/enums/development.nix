{_, ...}: let
  mkVal = _.mkCaseInsensitiveListValidator;
in {
  /**
  Development languages - programming and scripting languages.

  Supported languages for development environment configuration.

  # Categories
  - Systems: rust, zig, c, cpp, go
  - Scripting: python, javascript, typescript, lua
  - Shell: sh, bash, pwsh, powershell
  - Functional: haskell, nix

  # Structure
  ```nix
  {
    values = [ "python" "rust" "zig" "nix" ... ];
    validator = { check, list };
  }
  ```

  # Usage
  ```nix
  # Validate a language
  _lib.devLanguages.validator.check { name = "Python"; }  # => true

  # Check if user knows multiple languages
  _lib.areAllInList ["python" "rust"] _lib.devLanguages.values true

  # Get all supported languages
  _lib.devLanguages.values
  ```
  */
  devLanguages = let
    values = [
      "python"
      "rust"
      "zig"
      "nix"
      "sh"
      "bash"
      "pwsh"
      "powershell"
      "c"
      "cpp"
      "go"
      "javascript"
      "typescript"
      "lua"
      "haskell"
    ];
  in {
    inherit values;
    validator = mkVal values;
  };
}
