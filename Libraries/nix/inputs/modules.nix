{
  _,
  lib,
  ...
}: let
  inherit (_.inputs.resolution) inputs;
  inherit (lib.lists) optionals;

  mkModule = {
    name,
    modules ? homeModules,
    variant ? "default",
  }:
    modules.${name}.${variant} or {};

  coreModules = {class ? "nixos", ...}:
    (
      if class == "darwin"
      then [
        (inputs.home-manager.darwinModules.home-manager or {})
        (inputs.stylix.darwinModules.stylix or {})
      ]
      else [
        (inputs.home-manager.nixosModules.home-manager or {})
        (inputs.stylix.nixosModules.stylix or {})
        (inputs.catppuccin.nixosModules.default or {})
        (inputs.chaotic.nixosModules.default or {})
      ]
    )
    ++ optionals (class == "darwin") [
      {
        system = {
          checks.verifyNixPath = false;
          darwinVersionSuffix = ".${
            inputs.nix-darwin.shortRev or
            inputs.nix-darwin.dirtyShortRev or
            "dirty"
          }";
          darwinRevision =
            inputs.nix-darwin.rev or inputs.nix-darwin.dirtyRev or "dirty";
        };
      }
    ];

  homeModules = {
    dank-material-shell = {
      default = inputs.dank-material-shell.homeModules.default or {};
      niri = inputs.dank-material-shell.homeModules.niri or {};
    };
    noctalia-shell = inputs.noctalia-shell.homeModules or {};
    caelestia = inputs.caelestia.homeManagerModules or {};
    catppuccin = inputs.catppuccin.homeModules or {};
    nvf = {default = inputs.nvf.homeManagerModules.default or {};};
    plasma = {default = inputs.plasma.homeModules.plasma-manager or {};};
    zen-browser = {
      twilight = inputs.zen-browser.homeModules.twilight or {};
      default = inputs.zen-browser.homeModules.default or {};
      beta = inputs.zen-browser.homeModules.beta or {};
    };
  };

  mkModules = {class ? "nixos", ...}: let
    path = "${inputs.nixpkgs}/nixos/modules";
    base = import "${path}/module-list.nix";
    core = coreModules {inherit class;};
    home = homeModules;
    all = {
      baseModules = base;
      coreModules = core;
      homeModules = home;
      modulesPath = path;
    };
  in
    {inherit all base core home path;} // all;

  exports = {
    inherit
      inputs
      coreModules
      homeModules
      mkModule
      mkModules
      ;
    getCoreInputModules = coreModules;
    getHomeInputModules = homeModules;
    getInputs = inputs;
    mkInputModules = mkModules;
    mkInputModule = mkModule;
  };
in
  exports
  // {
    _rootAliases = {
      inherit
        (exports)
        getInputs
        getCoreInputModules
        getHomeInputModules
        mkInputModules
        mkInputModule
        ;
    };
  }
