{ lib, paths, ... }:
let
  # inherit (paths.bins) dev eda;
  # local = host.flake or "/home/craole/.dots";
  inherit (lib.modules) mkForce;

  local = paths.local.flake;
  store = paths.store.flake;
  inherit (paths.local.binaries) dev eda gyt;
  variables = {
    DOTS = mkForce local;
    DOTS_STORE = mkForce store;
  };
  aliases = {
    ".." = ''cd .. || exit 1'';
    "..." = ''cd ../.. || exit 1'';
    "...." = ''cd ../../.. || exit 1'';
    "....." = ''cd ../../../.. || exit 1'';
    ".dots" = ''cd ${local} || exit 1'';
    devdots = ''${dev} ${local}'';
    vscdots = ''${eda} --dots'';
    hxdots = ''${eda} --dots --helix'';
    inherit dev gyt eda;
  };
  environment = {
    inherit variables;
    sessionVariables = variables;
    shellAliases = aliases;
  };
in
{
  _module.args.config = { inherit environment; };
  config = { inherit environment; };
  # environment = {
  #   inherit variables;
  #   sessionVariables = variables;
  #   shellAliases = aliases;
  # };

}
