{ lib, pkgs }:
let
  inherit (lib.strings) escapeShellArg;
  inherit (lib.licenses) mit;
  flakeEval = import ./lib.nix { inherit lib; };
  example = command: desc: ''
    \n\e[33m${escapeShellArg command}\e[0m - ${escapeShellArg desc}
  '';
in
pkgs.stdenv.mkDerivation {
  pname = "repl";
  version = "1.0";

  buildInputs = with pkgs; [
    coreutils
    gnused
  ];

  installPhase = ''
    mkdir -p $out/bin
    cat > $out/bin/repl <<'EOF'
    #!/bin/sh
    case "$1" in
      "-h"|"--help"|"help")
        printf "%b\n\e[4mUsage\e[0m:\n" \
          "${example "repl" "Loads system flake if available."}" \
          "${example "repl /path/to/flake.nix" "Loads specified flake."}"
      ;;
      *)
        if [ -z "$1" ]; then
          nix repl "${flakeEval.flake}"
        else
          nix repl --arg flakePath "$(
            readlink -f "$1" | sed 's|/flake.nix||'
          )" "${flakeEval.flake}"

        fi
      ;;
    esac
    EOF
    chmod +x $out/bin/repl
  '';

  meta = {
    description = "A shell script to load the system flake or a specified flake.";
    license = mit;
    maintainers = [ "Craig 'Craole' Cole" ];
  };
}
