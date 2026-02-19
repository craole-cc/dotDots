{lib, ...}: let
  /**
  mkShellApp - A helper function to create a shell script application with runtime dependencies
  and optional aliases.

  # Arguments
  - name (string):            The name of the application
  - inputs (list, optional):  List of packages to include in the runtime PATH (default: [])
  - command (string):         The shell script content to execute
  - prefix (string, optional): Prefix to add to command and alias names (default: "")
  - aliases (list, optional): List of alias specifications {name, description, prefix?}
  - description (string, optional): Description of the command for help text

  # Returns
  An attrset containing the main application and all its aliases

  # Example
  ```nix
  mkShellApp {
    name = "dots";
    prefix = ".";
    inputs = with pkgs; [ rust-script ];
    command = ''
      exec rust-script "$@"
    '';
    description = "Main dotfiles CLI";
    aliases = [
      {name = "rebuild"; description = "Rebuild the system";}
      {name = "update"; description = "Update flake inputs";}
    ];
  }
  ```
  Returns: { ".dots" = <derivation>; ".rebuild" = <derivation>; ".update" = <derivation>; }
  */
  mkShellApp = {
    pkgs,
    /*
    The name of the script to write.

    Type: String
    */
    name,
    /*
    The shell script's text, not including a shebang.

    Type: String
    */
    command,
    /*
    Inputs to add to the shell script's `$PATH` at runtime.

    Type: [String|Derivation]
    */
    inputs ? [],
    /*
    Prefix to add to the command and alias names.

    Type: String
    */
    prefix ? "",
    /*
    List of aliases to create for this command.
    Each alias is an attrset with {name, description, prefix?}.

    Type: [{name: String, description: String, prefix?: String}]
    */
    aliases ? [],
    /*
    Optional description for the command (used in help text).

    Type: String
    */
    description ? null,
    /*
    Extra environment variables to set at runtime.

    Type: AttrSet
    */
    runtimeEnv ? null,
    /*
    `stdenv.mkDerivation`'s `meta` argument.

    Type: AttrSet
    */
    meta ? {},
    /*
    `stdenv.mkDerivation`'s `passthru` argument.

    Type: AttrSet
    */
    passthru ? {},
    /*
    The `checkPhase` to run. Defaults to `shellcheck` on supported
    platforms and `bash -n`.

    The script path will be given as `$target` in the `checkPhase`.

    Type: String
    */
    checkPhase ? null,
    /*
    Checks to exclude when running `shellcheck`, e.g. `[ "SC2016" ]`.

    See <https://www.shellcheck.net/wiki/> for a list of checks.

    Type: [String]
    */
    excludeShellChecks ? [],
    /*
    Extra command-line flags to pass to ShellCheck.

    Type: [String]
    */
    extraShellCheckFlags ? [],
    /*
    Bash options to activate with `set -o` at the start of the script.

    Defaults to `[ "errexit" "nounset" "pipefail" ]`.

    Type: [String]
    */
    bashOptions ? [
      "errexit"
      "nounset"
      "pipefail"
    ],
    /*
    Extra arguments to pass to `stdenv.mkDerivation`.

    :::note{.caution}
    Certain derivation attributes are used internally,
    overriding those could cause problems.
    :::

    Type: AttrSet
    */
    derivationArgs ? {},
    /*
    Whether to inherit the current `$PATH` in the script.

    Type: Bool
    */
    inheritPath ? true,
  }: let
    fullName = "${prefix}${name}";

    #> Create the main application
    mainApp = pkgs.writeShellApplication {
      name = fullName;
      inherit
        bashOptions
        checkPhase
        derivationArgs
        excludeShellChecks
        extraShellCheckFlags
        inheritPath
        runtimeEnv
        ;
      meta =
        meta
        // lib.optionalAttrs (description != null) {
          inherit description;
        };
      passthru =
        passthru
        // {
          inherit aliases prefix;
          cmdDescription = description;
        };
      runtimeInputs = inputs;
      text = command;
    };

    #> Create alias applications
    aliasApps =
      map (aliasSpec: let
        aliasPrefix = aliasSpec.prefix or prefix;
        aliasName = "${aliasPrefix}${aliasSpec.name}";
      in {
        name = aliasName;
        value = pkgs.writeShellApplication {
          name = aliasName;
          runtimeInputs = [mainApp];
          text = ''exec ${fullName} ${aliasSpec.name} "$@"'';
          meta = {
            description = aliasSpec.description or "Alias for ${fullName} ${aliasSpec.name}";
          };
          passthru = {
            aliasOf = mainApp;
            aliasCmd = aliasSpec.name;
          };
        };
      })
      aliases;
  in
    #> Return attrset with main app and all aliases
    {${fullName} = mainApp;}
    // builtins.listToAttrs aliasApps;

  exports = {inherit mkShellApp;};
in
  exports // {_rootAliases = exports;}
