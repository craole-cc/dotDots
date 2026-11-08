/**
Install `hermes-team-report` for the configured Hermes home.

Run without arguments to print a JSON object whose `profiles` array contains
the sorted directory names under `${HERMES_HOME}/profiles`. A missing profiles
directory produces an empty array; the listing is independent of `cfg.profiles`.

Run with `--check` to also require `profiles/<name>/profile.yaml` for each
enabled profile in `cfg.profiles`. The helper prints the same listing, reports
missing files on stderr, and exits with status 1 if any are missing. Unknown
arguments exit with status 2.
*/
{
  cfg,
  lix,
  ...
}: let
  inherit (lix.attrsets.transformation) filterAttrs mapAttrsToList;
  inherit (lix.strings.construction) concatStringsSep;
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (lix.toolkit.write) bin;
  inherit (lix.toolkit.binaries) rust-script;

  #> Quote each environment value as one shell argument, including paths with spaces.
  mkVar = key: value: "export ${key}=${escapeShellArg value}";

  #> Replace the wrapper with the toolkit's Rust runner and forward all CLI arguments.
  mkExec = cmd: script: ''
    exec ${
      escapeShellArg (toString cmd)
    } ${
      escapeShellArg (toString script)
    } "$@"
  '';

  #? The Rust helper splits this enabled-profile roster on whitespace for --check.
  #? Disabled declarations are excluded; the on-disk listing may contain other names.
  declaredNames = concatStringsSep " " (
    mapAttrsToList (name: _profile: name)
    (filterAttrs (_name: profile: profile.enable) cfg.profiles)
  );
in {
  outputs.home.packages = [
    (bin "hermes-team-report" ''
      ${mkVar "HERMES_HOME" cfg.home.path}
      ${mkVar "HERMES_DECLARED_PROFILES" declaredNames}
      ${mkExec rust-script ./report.rs}
    '')
  ];
}
