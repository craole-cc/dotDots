{ paths, flake, ... }:
let
  # inherit (paths.bins) dev eda;
  # local = host.flake or "/home/craole/.dots";
  local = paths.base;
  store = flake.outPath;
  variables = {
    DOTS = local;
    DOTS_STORE = store;
  };
  aliases = {
    ".." = ''cd .. || exit 1'';
    "..." = ''cd ../.. || exit 1'';
    "...." = ''cd ../../.. || exit 1'';
    "....." = ''cd ../../../.. || exit 1'';
    ".dots" = ''cd ${local} || exit 1'';
    # devdots = ''${dev} $DOTS'';
    # vscdots = ''${eda} --dots'';
    # hxdots = ''${eda} --dots --helix'';
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
