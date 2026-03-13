{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  shellHook = ''
    export NIX_CONFIG="experimental-features = nix-command flakes"
    exec nix repl --file default.nix
  '';
}
