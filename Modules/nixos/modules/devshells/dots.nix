{ pkgs, ... }:
{
  devShells.default = pkgs.mkShell {
    name = "nixos-config-shell";
    meta.description = "Dev environment for nixos-config";
    packages = with pkgs; [
      just
      colmena
      nixd
      nix-output-monitor
      inputs'.agenix.packages.default
    ];
  };

  # pre-commit.settings = {
  #   hooks.nixpkgs-fmt.enable = true;
  # };
}
