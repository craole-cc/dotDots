{
  config,
  lib,
  lix,
  pkgs,
  user,
  ...
}: let
  app = "foot";
  cmd = "feet";
  inherit (lib) getExe';
  inherit (lib.modules) mkIf;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.attrsets.predicates) waylandEnabled;

  # Terminal role checks
  terminalConfig = user.applications.terminal or {};
  isPrimary = terminalConfig.primary or null == app;
  isSecondary = terminalConfig.secondary or null == app;
  isWaylandAvailable = waylandEnabled {
    inherit config;
    interface = user.interface or {};
  };
  isExplicitlyAllowed = isIn app (user.applications.allowed or []);
  isAllowed =
    (isPrimary || isSecondary || isExplicitlyAllowed)
    && isWaylandAvailable;

  baseVars = {TERMINAL_ID = app;};
  roleVars =
    if isPrimary
    then {TERMINAL = cmd;}
    else if isSecondary
    then {TERMINAL_ALT = cmd;}
    else {};
  sessionVariables = baseVars // roleVars;

  #~@ Package and binaries
  package = pkgs.${app};
  binFoot = getExe' package app;
  binFootClient = getExe' package "footclient";

  # Foot client wrapper script
  bin = pkgs.writeShellScriptBin cmd ''
    if ${binFootClient} --no-wait 2>/dev/null; then exit 0 ; else
      ${binFoot} --server &
      sleep 0.1
      exec ${binFootClient}
    fi
  '';
in {
  config = mkIf isAllowed {
    programs.${app} = {
      enable = true;
      inherit package;
      server.enable = true;
      settings =
        (import ./settings.nix)
        // (import ./input.nix)
        // (import ./themes.nix);
    };

    home = {
      packages = [bin];
      inherit sessionVariables;
    };
  };
}
