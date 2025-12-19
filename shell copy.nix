{pkgs ? import <nixpkgs> {}}: {
  default = pkgs.mkShell {
    packages = with pkgs; [
      nix
      helix
      alejandra
      git
      rust-script
      rustfmt
      gcc

      nil
      nixd
      nixfmt
      shfmt
      shellcheck-minimal
    ];

    shellHook = ''

      #> Create a simple wrapper script for 'repl' in .direnv/bin
      WRAPPER_DIR="$PWD/.direnv/bin"
      mkdir -p "$WRAPPER_DIR"

      #> Create repl wrapper that calls nix-repl
      cat > "$WRAPPER_DIR/repl" << 'EOF'
      #!/bin/sh
      exec nix-repl "$@"
      EOF

      chmod +x "$WRAPPER_DIR/repl"

      #> Add wrapper directory to PATH (at front so it shadows if needed)
      export PATH="$WRAPPER_DIR:$PATH"

      printf "🚀 Run 'repl' to start Nix REPL\n"
    '';
  };
}
