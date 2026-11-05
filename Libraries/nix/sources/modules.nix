{
  _,
  _default,
  ...
}: let
  __doc = ''
    Input Modules Resolution

    Extracts and structures NixOS, Darwin, and Home Manager modules provided
    by flake inputs. It categorizes them so they can be easily injected into
    the system evaluation pipeline.
  '';

  inherit (_.sources.inputs) resolveInputs;
  inherit (_.content.emptiness) isEmpty;
  inherit (_.lists.construction) optionals;

  __exports = {
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
      else modules.home or modules;
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
  }:
    with inputs;
      (
        if class == "darwin"
        then [
          (age.darwinModules.default or {})
          (home-manager.darwinModules.home-manager or {})
          (stylix.darwinModules.stylix or {})
        ]
        else [
          (age.nixosModules.age or {})
          (catppuccin.nixosModules.default or {})
          (chaotic.nixosModules.default or {})
          (dux-shell.nixosModules.default or {})
          (dux-calendar.nixosModules.default or {})
          (dux-files.nixosModules.default or {})
          (dux-greeter.nixosModules.default or {})
          (dux-plugins.nixosModules.default or {})
          (home-manager.nixosModules.home-manager or {})
          (llmhop.nixosModules.default or {})
          (niri.nixosModules.default or {})
          (stylix.nixosModules.stylix or {})
        ]
      )
      ++ optionals (class == "darwin") [
        {
          system = {
            checks.verifyNixPath = false;
            darwinVersionSuffix = ".${
              nix-darwin.shortRev or nix-darwin.dirtyShortRev or "dirty"
            }";
            darwinRevision = nix-darwin.rev or nix-darwin.dirtyRev or "dirty";
          };
        }
      ];

  /**
  Attrset of all home-manager modules provided by flake inputs.
  */
  mkHome = {inputs ? _default.inputs}:
    with inputs; {
      dms-shell = dux-shell.homeModules or {};
      dsearch = dux-search.homeModules or {};
      dank-calendar = dux-calendar.homeModules or {};
      dux-files = dux-files.homeModules or {};
      dms-plugin-registry = dux-plugins.homeModules or {};
      niri = {
        default = niri.homeModules.default or {};
        stylix = niri.homeModules.stylix or {};
      };
      hermes-agent = hermes-agent.homeManagerModules or {};
      noctalia-shell = noctalia-shell.homeModules or {};
      caelestia = caelestia.homeManagerModules or {};
      catppuccin = catppuccin.homeModules or {};
      nvf = nvf.homeManagerModules or {};
      plasma.default = plasma.homeModules.plasma-manager or {};
      zen-browser = let
        default = zen-browser.homeModules.default or {};
        twilight = zen-browser.homeModules.twilight or default;
        beta = zen-browser.homeModules.beta or default;
      in {inherit default beta twilight;};
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
    resolved.inputs =
      if inputs ? nixpkgs
      then inputs
      else (resolveInputs {}).inputs;

    path = "${resolved.inputs.nixpkgs}/nixos/modules";
    base = import "${path}/module-list.nix";
    core = mkCore {
      inherit class;
      inherit (resolved) inputs;
    };
    home = mkHome {
      inherit (resolved) inputs;
    };
    all = {
      baseModules = base;
      coreModules = core;
      homeModules = home;
      modulesPath = path;
    };
  in
    all // {inherit all base core home path;};
in
  __exports.internal
  // {
    inherit __doc;
    __rootAliases = __exports.external;
  }
