{
  nixosConfig,
  host,
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;

  loc = nixosConfig.location or {};
  lat = loc.latitude or null;
  lng = loc.longitude or null;
  usegeoclue = (loc.provider or null) == "geoclue2";

  dots = host.paths.dots or config.home.homeDirectory + "/.dots";
  style = nixosConfig.interface.style or {};
  mode = style.mode or {};
  auto = mode.auto or false;
  hostname = nixosConfig.networking.hostName or "$(hostname)";

  enable = auto && (lat != null) && (lng != null);

  commands = {
    gnuSed = "${pkgs.gnused}/bin/sed -i";
    nixRebuild = "sudo ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake ";
  };

  mkThemeScript = modeType: ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Update current mode in host config
    ${gnuSed} 's/current = "[^"]*";/current = "${modeType}";/' ${dots}/hosts/${hostname}/default.nix

    # Rebuild NixOS configuration
    ${nixRebuild} ${dots}#${hostname}
  '';
in {
  services.darkman = mkIf enable {
    inherit enable;

    settings = {
      inherit lat lng usegeoclue;
    };

    darkModeScripts = {
      nixos-theme = mkThemeScript "dark";
    };

    lightModeScripts = {
      nixos-theme = mkThemeScript "light";
    };
  };
}
