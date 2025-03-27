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
  #!/bin/sh

  #@ Define necessary binaries explicitly
  export CMD_READLINK="${coreutils}/bin/readlink"
  export CMD_SED="${gnused}/bin/sed"

  #@ Ensure FLAKE is a valid path
  export FLAKE="${escapeShellArg (flakeEval.flake or "/")}"

  #@ Use the script from the repl package's bin directory
  "${replScript}" "$@"
''
