{
  pkgs ? import <nixpkgs> { },
  ...
}:
{
  default = pkgs.mkShell {
    # NIX_CONFIG = "extra-experimental-features = nix-command flakes ca-derivations";
    NIX_CONFIG = "extra-experimental-features = nix-command flakes";
    nativeBuildInputs = with pkgs; [
      gh
      git
      helix
      # sops
      # ssh-to-age
      # gnupg
      # age

    ];
  };
}

#TODO: This should simply enable flakes then run nix develop
