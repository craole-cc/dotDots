{_, ...}: let
  inherit (_.lists.generators) mkEnum;
  inherit (_.testing.unit) mkTest runTests;

  /**
  Shells - command-line shell options.

  Available interactive shells for user sessions and scripting.


  # POSIX-Compatible
  - bash: Bourne Again SHell (most common)
  - zsh: Z Shell (extended Bourne, powerful)
  - sh: POSIX shell (basic)
  - dash: Debian Almquist Shell (fast, minimal)

  # Modern
  - fish: Friendly Interactive SHell (user-friendly)
  - nushell: Structured data shell (typed, tables)
  - pwsh: PowerShell Core (object-oriented)
  - elvish: Expressive programming language shell

  # Alternative
  - tcsh: C Shell (BSD heritage)
  - ksh: Korn Shell (UNIX standard)

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
  shells = mkEnum [
    "bash"
    "dash"
    "elvish"
    "fish"
    "ksh"
    "nushell"
    "powershell"
    "pwsh"
    "sh"
    "tcsh"
    "zsh"
  ];
in {
  inherit shells;

  _rootAliases = {
    shellsList = shells;
  };

  _tests = runTests {
    shells = {
      validatesBash = mkTest true (shells.validator.check "bash");
      validatesZsh = mkTest true (shells.validator.check "zsh");
      validatesFish = mkTest true (shells.validator.check "fish");
      caseInsensitive = mkTest true (shells.validator.check "NUSHELL");
    };
  };
}
