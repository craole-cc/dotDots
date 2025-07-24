{pkgs ? import <nixpkgs> {}}: {
  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes";
    shellHook = "nix develop";
  };
}
