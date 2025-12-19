{pkgs ? import <nixpkgs> {}}: {
  default = pkgs.mkShell {
    shellHook = ''
      export NIX_CONFIG="experimental-features = nix-command flakes"
      nix develop .#shell
    '';
  };
}
