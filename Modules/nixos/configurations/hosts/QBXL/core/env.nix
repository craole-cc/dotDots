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
in
{
  environment = {
    inherit (dots) variables;

    systemPackages = [
      (writeShellScriptBin ".dots" ''
        exec "${flake}/Bin/shellscript/project/.dots" "$@"
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
