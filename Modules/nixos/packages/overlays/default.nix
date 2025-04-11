# https://nixos.wiki/wiki/Overlays
{ inputs, ... }:
let
  inherit (inputs.nixPackages.lib) mkDefault;
in
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

  #DOC Adds pkgs.stable with default config
  fromStable = final: _: {
    stable = import inputs.nixPackagesStable {
      system = final.system;
      config.allowUnfree = mkDefault true;
    };
  };

  #DOC Include modifications to existing packages with defaults
  modifications = final: prev: {
    brave = prev.brave.override {
      commandLineArgs = mkDefault "--password-store=gnome-libsecret";
    };
  };

  #DOC Add custom packages and plugins
  additions =
    final: prev:
    import ../custom { pkgs = final; }
    // {
      vimPlugins = (prev.vimPlugins or { }) // import ../plugins/vim { pkgs = final; };
    };
}
