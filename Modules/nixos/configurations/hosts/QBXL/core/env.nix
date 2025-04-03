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
  # dotsScript = local + shellscript + "/project/.dots";
  devScript = local + shellscript + "/project/nix/devnix";
  edaScript = local + shellscript + "/packages/alias/edita";
in
{
  environment = {
    inherit (dots) shellAliases;
    variables = dots.variables // {
      DOTS = local;
    };
    # TODO: Add the bins to PATH

    systemPackages = [
      (writeShellScriptBin "dotshell" ''
        dev "${local}"
      '')
      (writeShellScriptBin "dev" ''
        set -e
        chmod +x "${devScript}"
        "${devScript}" "$@"
      '')
      (writeShellScriptBin "eda" ''
        set -e
        chmod +x "${edaScript}"
        "${edaScript}" "$@"
      '')
    ];
  };
}
