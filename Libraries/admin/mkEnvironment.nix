{
  host,
  flake,
  paths,
  ...
}:
let
  inherit (paths.bins) dev eda;
  local = host.flake or "/home/craole/.dots";
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
    ".dots" = ''cd "$DOTS" || exit 1'';
    devdots = ''${dev} $DOTS'';
    vscdots = ''${eda} --dots'';
    hxdots = ''${eda} --dots --helix'';
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
