{ inputs, ... }:
{
  imports = [
    (inputs.git-hooks + /flake-module.nix)
  ];
  perSystem =
    {
      inputs',
      config,
      pkgs,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        name = "dotDots";
        meta.description = "Dev environment for dotDots";
        inputsFrom = [ config.pre-commit.devShell ];
        packages = with pkgs; [
          just
          colmena
          nixd
          nix-output-monitor
          inputs'.agenix.packages.default
          gitui
        ];
      };

      pre-commit.settings = {
        hooks.nixfmt-rfc-style.enable = true;
        # hooks.nixpkgs-fmt.enable = true;
      };
    };
}
