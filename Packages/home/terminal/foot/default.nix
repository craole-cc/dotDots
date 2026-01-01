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
  inherit (lix.applications.generators) userApplicationConfig userApplication;

  app = userApplication {
    inherit user pkgs config;
    name = "foot";
    kind = "terminal";
    customCommand = "feet";
    resolutionHints = ["foot" "feet"];
    requiresWayland = true;
    # debug = true;
  };

  # bin = rec {
  #   foot = getExe' app.package "foot";
  #   footclient = getExe' app.package "footclient";
  #   feet = pkgs.writeShellScriptBin app.command ''
  #     if ${footclient} --no-wait 2>/dev/null; then exit 0 ; else
  #       ${foot} --server &
  #       sleep 0.1
  #       exec ${footclient}
  #     fi
  #   '';
  # };

  bin = rec {
    foot = getExe' app.package "foot";
    footclient = getExe' app.package "footclient";

    feet = pkgs.writeShellScriptBin "foot" ''
      if ! ${footclient} --no-wait 2>/dev/null; then
        ${foot} --server &
        sleep 0.1
      fi
      exec ${footclient} "$@"
    '';

    # Create a complete package with desktop files and icons
    feetPackage = pkgs.symlinkJoin {
      name = "feet";
      paths = [feet app.package];
      postBuild = ''
        # Override the foot binary with our wrapper
        rm -f $out/bin/foot
        ln -s ${feet}/bin/foot $out/bin/foot
        ln -s $out/bin/foot $out/bin/feet
      '';
    };
  };

  cfg = userApplicationConfig {
    inherit app user pkgs config;
    extraPackages = [bin.feetPackage];
    extraProgramConfig = {
      server.enable = true;
      settings =
        {}
        // (import ./settings.nix)
        // (import ./input.nix)
        // (import ./themes.nix)
        // {};
    };
  };
in {
  config = mkIf cfg.enable {
    inherit (cfg) programs home;
  };
}
