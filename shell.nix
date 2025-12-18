{pkgs ? null}: let
  finalPkgs =
    if pkgs != null
    then pkgs
    else
      (
        if builtins ? getFlake
        then with builtins; (getFlake (toString ./.)).inputs.nixosCore.legacyPackages.${currentSystem}
        else import <nixpkgs> {}
      );
in {
  default = finalPkgs.mkShell {
    packages = with finalPkgs; [
      nix
      helix
      alejandra
      git
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

      printf "🪧 Run 'repl' to start Nix REPL\n"
    '';
  };
}
