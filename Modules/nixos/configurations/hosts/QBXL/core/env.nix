{
  pkgs,
  paths,
  config,
  dots,
  ...
}:
let
  inherit (pkgs) writeShellScriptBin;
  inherit (paths) flake parts;
  inherit (parts.bin) shellscript;
  local = flake.${config.networking.hostName};
  dotsScript = local + shellscript + "/project/.dots";
  edaScript = local + shellscript + "/packages/alias/edita";
in
{
  environment = {
    variables = dots.variables // {
      DOTS = local;
      TEST = "test ${local}";
      VISUAL = "eda";
      EDITOR = "eda --helix";
      eda = edaScript;
      dots = dotsScript;
    };

    systemPackages = [
      (writeShellScriptBin ".dots" ''
        set -e
        chmod +x "${dotsScript}"
        "${dotsScript}" "$@"
      '')
      (writeShellScriptBin "eda" ''
        set -e
        chmod +x "${edaScript}"
        "${edaScript}" "$@"
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
