# https://nixos.wiki/wiki/Overlays
{ inputs, ... }:
{
  #DOC For every flake input, aliases 'pkgs.inputs.${flake}' to
  #DOC 'inputs.${flake}.packages.${pkgs.system}' or
  #DOC 'inputs.${flake}.legacyPackages.${pkgs.system}'
  fromInputs = final: _: {
    inputs = builtins.mapAttrs (
      _: flake:
      let
        legacyPackages = (flake.legacyPackages or { }).${final.system} or { };
        packages = (flake.packages or { }).${final.system} or { };
      in
      if legacyPackages != { } then legacyPackages else packages
    ) inputs;
  };

  #DOC Adds pkgs.stable == inputs.nixPackagesStable.legacyPackages.${pkgs.system}
  fromStable = final: _prev: {
    stable = import inputs.nixPackagesStable {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  #DOC Include modifications to existing packages
  modifications = final: prev: {
    brave = prev.brave.override {
      commandLineArgs = "--password-store=gnome-libsecret";
    };
  };

  #DOC Add custom packages
  additions =
    final: prev:
    (import ../custom { pkgs = final; })
    // (inputs.hyprpanel.overlay final prev)
    // {
      rose-pine-hyprcursor = inputs.rose-pine-hyprcursor.packages.${prev.system}.default;
    };
}
