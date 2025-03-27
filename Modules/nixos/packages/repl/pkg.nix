{
  lib,
  coreutils,
  gnused,
  writeShellScriptBin,
}:
let
  inherit (lib) escapeShellArg;
  flakeEval = import ./lib.nix { inherit lib; };
  replScript = ./repl.sh;
in
writeShellScriptBin "repl" ''
  #!/usr/bin/env bash

  #@ Define necessary binaries explicitly
  export CMD_READLINK="${coreutils}/bin/readlink"
  export CMD_SED="${gnused}/bin/sed"

  #@ Ensure FLAKE is a valid path
  export FLAKE="${escapeShellArg (flakeEval.flake or "/")}"

  #@ Source the external script
  # shellcheck source=./repl.sh
  . "${replScript}"
''
