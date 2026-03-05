{
  _,
  lib,
  ...
}: let
  inherit (_.lists.predicates) isIn;
  inherit (lib.strings) hasInfix;

  appsAllowed = user: user.applications.allowed or [];

  homeMods = {inputs}: {
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
    homeMods.${name}.${variant} or {};

  mkHomeModuleApps = user: {
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

  mkHome = {};

  exports = {inherit homeMods mkHomeModule mkHomeModuleApps mkHome;};
in
  exports // {_rootAliases = exports;}
