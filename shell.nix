{pkgs ? import <nixpkgs> {}}: {
  default = pkgs.mkShell {
    packages = with pkgs; [
      nix
      helix
      alejandra
      git
    ];

    env = rec {
      NIX_CONFIG = "extra-experimental-features = nix-command flakes";
      NIX_FLAKE = toString ./.;
      NIX_REPL = "${NIX_FLAKE}/Bin/shellscript/project/nix/nix-repl";
    };

    shellHook = ''
      printf "🚀 Project shell loaded\n"
      printf "FLAKE: %s\n" "$NIX_FLAKE"
      printf "REPL: %s\n" "$NIX_REPL"

      # Define shell functions (not aliases)
      repl() {
        if [ -f "$NIX_REPL" ]; then
          "$NIX_REPL" "$@"
        else
          printf "Error: REPL not found at %s\n" "$NIX_REPL" >&2
          return 1
        fi
      }

      nix-repl() {
        repl "$@"
      }

      printf "Available commands:\n"
      printf "  repl       - Run Nix REPL\n"
      printf "  nix-repl   - Same as 'repl'\n"
    '';
  };
}
