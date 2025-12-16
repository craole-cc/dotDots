{_, ...}: let
  inherit (_.lists.generators) mkEnum;
  inherit (_.testing.unit) mkTest runTests;
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
  languages.validator.check { name = "Python"; }  # => true

  # Check if user knows multiple languages
  _lib.lists.predicates.isIn ["python" "rust"] _lib.lists.enums.development.languages.values true

  # Get all supported languages
  _lib.devLanguages.values
  ```
  */
  languages = mkEnum [
    #~@ Systems languages
    "rust"
    "zig"
    "c"
    "cpp"
    "go"
    "java"

    #~@ Scripting languages
    "python"
    "javascript"
    "typescript"
    "ruby"
    "perl"
    "php"

    #~@ Functional languages
    "haskell"
    "nix"
    "elixir"
    "ocaml"
  ];
in {
  inherit languages;

  _rootAliases = {
    devLanguagesList = languages;
  };

  _tests = runTests {
    languages = {
      validatesRust = mkTest true (languages.validator.check "rust");
      validatesPython = mkTest true (languages.validator.check "python");
      caseInsensitive = mkTest true (languages.validator.check "JAVASCRIPT");
    };
  };
}
