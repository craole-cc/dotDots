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
    '';
  };
}
