{
  host,
  flake,
  paths,
  ...
}:
let
  inherit (paths) bins;
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
    devdots = ''${bins.dev} $DOTS'';
    vscdots = ''${bins.eda} --dots'';
    hxdots = ''${bins.eda} --dots --helix'';
    eda = ''${bins.eda}'';
    dev = ''${bins.dev}'';
  };
in
{
  environment = {
    inherit variables;
    sessionVariables = variables;
    shellAliases = aliases;
  };
}
