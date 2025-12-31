{
  config,
  lib,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe';
  inherit (lix.applications.generators) application program;

  app = application {
    inherit user pkgs config;
    name = "foot";
    kind = "terminal";
    customCommand = "feet";
    resolutionHints = ["foot" "feet"];
    requiresWayland = true;
  };

  bin = rec {
    foot = getExe' app.package "foot";
    footclient = getExe' app.package "footclient";
    feet = pkgs.writeShellScriptBin app.command ''
      if ${footclient} --no-wait 2>/dev/null; then exit 0 ; else
        ${foot} --server &
        sleep 0.1
        exec ${footclient}
      fi
    '';
  };
in {
  config = mkIf app.isAllowed (program {
    inherit (app) name package sessionVariables;
    extraPackages = [bin.feet];
    extraConfig = {
      server.enable = true;
      settings =
        {}
        // (import ./settings.nix)
        // (import ./input.nix)
        // (import ./themes.nix)
        // {};
    };
  });
}
