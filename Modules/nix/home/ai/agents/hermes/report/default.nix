{
  cfg,
  lix,
  pkgs,
  ...
}: let
  inherit (lix.attrsets.transformation) filterAttrs mapAttrsToList;
  inherit (lix.strings.construction) concatStringsSep;
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (lix.toolkit) write;

  active = filterAttrs (_name: profile: profile.enable) cfg.profiles;

  #? rust-script source for the report helper. Reads the on-disk profile roster
  #? (the source of truth the gateway uses) and prints a compact JSON summary.
  #? --check exits non-zero if any declared profile is missing profile.yaml.
  reportRs = ./report.rs;

  declaredNames = concatStringsSep " " (mapAttrsToList (name: _profile: name) active);
in {
  outputs.home.packages = [
    (write.binWith "hermes-team-report" [pkgs.rust-script] ''
      export HERMES_HOME=${escapeShellArg cfg.home.path}
      export HERMES_DECLARED_PROFILES=${escapeShellArg declaredNames}
      exec ${pkgs.rust-script}/bin/rust-script ${reportRs} "$@"
    '')
  ];
}
