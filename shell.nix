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
      printf "🚀 Nix development shell loaded\n"

      #> Setup repl alias (Bin should already be in PATH from .envrc)
      if command -v nix-repl >/dev/null 2>&1; then
        alias repl='nix-repl'
        printf "Run 'repl' to start Nix REPL\n"
      else
        printf "Note: 'nix-repl' command not found in PATH\n" >&2
      fi
    '';
  };
}
