{pkgs ? import <nixpkgs> {}}: {
  default = pkgs.mkShell {
    packages = with pkgs; [
      nix
      helix
      alejandra
      git
    ];

    env = {
      NIX_CONFIG = "extra-experimental-features = nix-command flakes";
    };

    shellHook = ''
      printf "🚀 Project shell loaded\n"

      # Add current project's bin directory to PATH
      # This is where your nix-repl script should be symlinked
      PROJECT_BIN="$PWD/.bin"
      mkdir -p "$PROJECT_BIN"

      # Create symlink to the actual script
      if [ -f "$PWD/Bin/shellscript/project/nix/nix-repl" ]; then
        ln -sf "$PWD/Bin/shellscript/project/nix/nix-repl" "$PROJECT_BIN/repl"
        ln -sf "$PWD/Bin/shellscript/project/nix/nix-repl" "$PROJECT_BIN/nix-repl"
      fi

      export PATH="$PROJECT_BIN:$PATH"

      printf "Run 'repl' or 'nix-repl' to start Nix REPL\n"
    '';
  };
}
