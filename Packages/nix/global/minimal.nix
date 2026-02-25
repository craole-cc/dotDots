{pkgs}: let
  shellHook = ''
    export DOTS="$(pwd -P)"
    printf '╔══════════════════════════════════╗\n'
    printf '║     dotDots  ·  minimal shell    ║\n'
    printf '╚══════════════════════════════════╝\n'
    printf '  Run: nix develop .#dots  for the full environment\n\n'
  '';
in
  pkgs.mkShell {
    name = "minimal";

    packages = with pkgs; [
      git # ?version control
      nix-output-monitor # ?build feedback
      ripgrep # ?fast search
      fd # ?fast find
      jq # ?JSON
      lsd # ?ls
    ];

    inherit shellHook;
  }
