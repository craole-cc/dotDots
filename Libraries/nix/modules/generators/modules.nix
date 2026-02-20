{
  _,
  lib,
  ...
}: let
  inherit (_.lists.predicates) isIn;
  inherit (_.modules.generators.environment) mkEnvironment mkLocale;
  inherit (_.modules.generators.hardware) mkAudio mkFileSystems mkNetwork;
  inherit (_.modules.generators.software) mkNix mkBoot mkClean;
  inherit (_.modules.generators.style) mkFonts;
  inherit (_.modules.generators) core home;
  # inherit (_.modules.generators.users.home) mkHomeUsers;
  inherit (lib.lists) optionals;
  inherit (lib.modules) mkMerge;
  inherit (lib.strings) hasInfix;

  mkModules = {
    inputs,
    host,
    packages,
    specialArgs,
    config,
    overlays,
  }: let
    class = host.class or "nixos";
    modulesPath = "${inputs.nixpkgs}/nixos/modules";
    baseModules = import "${modulesPath}/module-list.nix";
    nixpkgs =
      {
        hostPlatform = host.system;
        inherit config overlays;
      }
      // (
        with inputs.nixpkgs; (
          if (host.class or "nixos") == "darwin"
          then {source = outPath;}
          else {flake.source = outPath;}
        )
      );
    coreModules =
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
      ]
      ++ [];

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
    mkHomeModule = {
      name,
      variant ? "default",
    }:
      homeModules.${name}.${variant} or {};

    appsAllowed = user: user.applications.allowed or [];
    mkHomeModuleApps = {
      # pkgs,
      user,
      # config,
    }: {
      #| Plasma Desktop Environment
      plasma = let
        name = "plasma";
        alt = "kde";
      in {
        isAllowed =
          hasInfix name (user.interface.desktopEnvironment or "")
          || hasInfix alt (user.interface.desktopEnvironment or "");
        module = mkHomeModule {inherit name;};
      };

      #| Caelestia Shell
      catppuccin = let
        name = "catppuccin";
        theme = user.interface.style.theme or {};
      in {
        isAllowed =
          isIn name (appsAllowed user)
          || hasInfix name (theme.light or "")
          || hasInfix name (theme.dark or "");
        module = mkHomeModule {inherit name;};
      };

      #| Caelestia Shell
      caelestia = let
        name = "caelestia";
      in {
        isAllowed = isIn ["${name}-shell" name] (
          (appsAllowed user)
          ++ [(user.applications.bar or null)]
        );
        module = mkHomeModule {inherit name;};
      };

      #| Dank Material Shell
      dank-material-shell = let
        name = "dank-material-shell";
      in {
        isAllowed = isIn [name "dank" "dms"] (
          (appsAllowed user)
          ++ [(user.applications.bar or null)]
        );
        module = mkHomeModule {inherit name;};
      };

      #| Noctalia Shell
      noctalia-shell = let
        name = "noctalia-shell";
      in {
        isAllowed = isIn ["noctalia-shell" "noctalia" "noctalia-dev"] (
          (appsAllowed user)
          ++ [(user.applications.bar or null)]
        );
        module = mkHomeModule {inherit name;};
      };

      #| NVF (Neovim Framework)
      nvf = let
        name = "nvf";
      in {
        isAllowed = isIn [name "nvim" "neovim"] (
          (appsAllowed user)
          ++ [(user.applications.editor.tty.primary or null)]
          ++ [(user.applications.editor.tty.secondary or null)]
        );
        module = mkHomeModule {inherit name;};
      };

      #| Firefox - Zen Browser
      zen-browser = let
        name = "zen-browser";
        alt = "zen";
        alt_names = [name alt "zen-twilight"];
        variant =
          if hasInfix "twilight" (user.applications.browser.firefox or "")
          then "twilight"
          else "default";
      in {
        isAllowed =
          hasInfix alt (user.applications.browser.firefox or "")
          || isIn alt_names (appsAllowed user);
        module = mkHomeModule {inherit name variant;};
      };
    };
    hostModules =
      [
        {inherit nixpkgs;}
        (
          {
            pkgs,
            config,
            paths,
            ...
          }:
            mkMerge [
              (mkNix {inherit host pkgs;})
              (mkNetwork {inherit host pkgs;})
              (mkBoot {inherit host pkgs;})
              (mkFileSystems {inherit host;})
              (mkLocale {inherit host;})
              (mkAudio {inherit host;})
              (mkFonts {inherit host pkgs;})
              # (mkStyle {inherit host pkgs;}) # TODO: Not ready, build errors
              (core.mkUsers {inherit host pkgs;})
              (home.mkUsers {inherit host specialArgs paths;})
              (mkEnvironment {inherit config host pkgs packages;})
              (mkClean {inherit host;})
            ]
        )
      ]
      ++ (host.imports or []);
  in {
    inherit
      modulesPath
      baseModules
      coreModules
      homeModules
      hostModules
      nixpkgs
      ;
  };

  exports = {inherit mkModules;};
in
  exports // {_rootAliases = exports;}
