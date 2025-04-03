{
  pkgs,
  paths,
  config,
  dots,
  ...
}:
let
  inherit (pkgs) writeShellScriptBin;
  flake = paths.flake.${config.networking.hostName};
  dotDots = flake + "/Bin/shellscript/project/.dots";
in
{
  environment = {
    # variables = {
    #   EDITOR = "hx";
    #   VISUAL = "code-insiders"; # TODO: Make this dynamic

    # } // { DOTS = flake; };
    variables = dots.variables // {
      DOTS = flake;
      TEST = "test ${flake}";
    };

    systemPackages = [
      (writeShellScriptBin ".dots" ''
        set -e
        chmod +x "${dotDots}"
        "${dotDots}" "$@"
      '')
      (writeShellScriptBin "vs" ''
        set -e
        chmod +x "${dotDots}"
        "${dotDots}" "$@"
      '')
      # (writeShellScriptBin "QBXL" (
      #   with QBXL;
      #   ''
      #     set -e
      #     printf "NixOS WSL Flake for QBXL [%s]\n/> Updating />\n" "${flake}"
      #       nix flake update --flake "${flake}"
      #     printf "/> Committing />\n"
      #       gitui || true
      #     printf "/> Rebuilding />\n"
      #       sudo nixos-rebuild switch --flake "${flake}" --show-trace --upgrade
      #   ''
      # ))
    ];
  };
}
