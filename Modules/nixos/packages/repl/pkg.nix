{
  lib,
  coreutils,
  gnused,
  writeShellScriptBin,
}:
let
  inherit (lib) escapeShellArg;
  flakeEval = import ./lib.nix { inherit lib; };
  replScript = builtins.readFile ./repl.sh;
in
writeShellScriptBin "repl" ''
  #@ Define necessary binaries explicitly
  CMD_READLINK="${coreutils}/bin/readlink"
  CMD_SED="${gnused}/bin/sed"

  export FLAKE=${escapeShellArg flakeEval.flake}

  #@ Source the external script (repl.sh), ensuring it can use the binaries
  . ${replScript}
''
