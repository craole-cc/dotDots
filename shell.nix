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
      printf "🚀 Project shell loaded\n"

      PROJECT_BIN="$PWD/.bin"
      mkdir -p "$PROJECT_BIN"

      if [ -f "$PWD/Bin/shellscript/project/nix/nix-repl" ]; then
        ln -sf "$PWD/Bin/shellscript/project/nix/nix-repl" "$PROJECT_BIN/repl"
        ln -sf "$PWD/Bin/shellscript/project/nix/nix-repl" "$PROJECT_BIN/nix-repl"
      fi

      export PATH="$PROJECT_BIN:$PATH"
      printf "Run 'repl' to start Nix REPL\n"
    '';
  };
}
