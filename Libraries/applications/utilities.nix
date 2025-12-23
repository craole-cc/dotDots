{pkgs, ...}: let
  /**
  mkApp - A helper function to create a shell script application with runtime dependencies.

  # Arguments
  - name (string):            The name of the application
  - inputs (list, optional):  List of packages to include in the runtime PATH (default: [])
  - command (string):         The shell script content to execute

  # Returns
  A derivation that is a shell script application with specified dependencies available at runtime

  # Example
  ```nix
  mkApp {
    inherit pkgs;
    name = "my-script";
    inputs = with pkgs;[ curl jq ];
    command = ''
      #!/bin/bash
      curl https://api.example.com | jq '.'
    '';
  }
  ```
  */
  mkShellApp = {
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
  }:
    pkgs.writeShellApplication {
      inherit
        bashOptions
        checkPhase
        derivationArgs
        excludeShellChecks
        extraShellCheckFlags
        inheritPath
        meta
        name
        passthru
        runtimeEnv
        ;
      runtimeInputs = inputs;
      text = command;
    };
  exports = {inherit mkShellApp;};
in
  exports // {_rootAliases = exports;}
