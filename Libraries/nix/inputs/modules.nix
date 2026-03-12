{
  _,
  lib,
  ...
}: let
  inherit (_.inputs.source) mkInputs;
  inherit (_.content.empty) isEmpty;
  inherit (lib.lists) optionals;

  exports = {
    internal = {
      inherit mkAll mkOne mkCore mkHome;
      mkModules = mkAll;
      mkModule = mkOne;
    };
    external = {
      mkInputModule = mkOne;
      mkInputModules = mkAll;
      mkCoreInputModules = mkCore;
      mkHomeInputModules = mkHome;
    };
  };

  /**
  Look up a module by name and variant from a modules attrset.

  # Type
  ```nix
  mkOne :: { name :: string, modules :: AttrSet?, variant :: string? } -> module
  ```
  */
  mkOne = {
    name,
    inputs ? {},
    modules ? {},
    variant ? "default",
  }: let
    mods =
      if isEmpty modules
      then inputs.home or (mkAll {}).home
      else modules;
  in
    mods.${name}.${variant} or {};

  /**
  Return the list of core NixOS/Darwin modules for a host class.

  # Type
  ```nix
  mkCore :: { class :: "nixos" | "darwin" } -> [module]
  ```
  */
  mkCore = {
    inputs,
    class ? "nixos",
  }: let
  in
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
            inputs.nix-darwin.shortRev
            or inputs.nix-darwin.dirtyShortRev
            or "dirty"
          }";
          darwinRevision =
            inputs.nix-darwin.rev or inputs.nix-darwin.dirtyRev or "dirty";
        };
      }
    ];

  /**
  Attrset of all home-manager modules provided by flake inputs.
  */
  mkHome = {inputs}: {
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

  /**
  Build the full module attrset for a host.

  # Type
  ```nix
  mkAll :: { class :: "nixos" | "darwin" } -> { all, base, core, home, path, ... }
  ```
  */
  mkAll = {
    inputs ? {},
    class ? "nixos",
    ...
  }: let
    inputs' =
      if inputs?nixpkgs
      then inputs
      else mkInputs {};

    path = "${inputs'.nixpkgs}/nixos/modules";
    base = import "${path}/module-list.nix";
    core = mkCore {
      inherit class;
      inputs = inputs';
    };
    home = mkHome {inputs = inputs';};
    all = {
      baseModules = base;
      coreModules = core;
      homeModules = home;
      modulesPath = path;
    };
  in
    {inherit all base core home path;} // all;
in
  exports.internal // {_rootAliases = exports.external;}
