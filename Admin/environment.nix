{ lib, paths, ... }:
let
  # inherit (paths.bins) dev eda;
  # local = host.flake or "/home/craole/.dots";
  inherit (lib.modules) mkForce;

  local = paths.local.flake;
  store = paths.store.flake;
  inherit (local.binaries) dev eda gyt;
  variables = {
    DOTS = mkForce local;
    DOTS_STORE = mkForce store;
  };
  aliases = {
    ".." = ''cd .. || exit 1'';
    "..." = ''cd ../.. || exit 1'';
    "...." = ''cd ../../.. || exit 1'';
    "....." = ''cd ../../../.. || exit 1'';
    ".dots" = ''cd $DOTS || exit 1'';
    # devdots = ''${dev} $DOTS'';
    # vscdots = ''${eda} --dots'';
    # hxdots = ''${eda} --dots --helix'';
    # gyt = ''${gyt}'';
    # eda = ''${eda}'';
    # dev = ''${dev}'';
  };
in
{
  environment = {
    inherit variables;
    sessionVariables = variables;
    shellAliases = aliases;
  };

}
