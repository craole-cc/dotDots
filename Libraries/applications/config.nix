{
  _,
  lib,
  ...
}: let
  inherit (lib.strings) hasInfix;
  inherit (_.applications.generators) userApplication;

  mkUserApps = {
    modules,
    pkgs,
    user,
    config,
  }: {
    noctalia-shell = let
      module = modules.noctalia-shell.default or {};
      appInfo = userApplication {
        inherit user pkgs config;
        name = "noctalia-shell";
        kind = "bar";
        resolutionHints = ["noctalia" "noctalia-dev"];
        debug = true;
      };
    in {
      inherit module;
      inherit
        (appInfo)
        name
        kind
        packageFound
        command
        basename
        identifiers
        isPrimary
        isSecondary
        isRequested
        isPlatformCompatible
        isAllowed
        sessionVariables
        ;
    };

    nvf = let
      module = modules.nvf.default or {};
      appInfo = userApplication {
        inherit user pkgs config;
        name = "nvf";
        kind = "editor";
        category = "tty";
        resolutionHints = ["nvim" "neovim"];
        debug = true;
      };
    in {
      inherit module;
      inherit
        (appInfo)
        name
        kind
        packageFound
        command
        basename
        identifiers
        isPrimary
        isSecondary
        isRequested
        isPlatformCompatible
        isAllowed
        sessionVariables
        ;
    };

    zen-browser = let
      variant =
        if hasInfix "twilight" (user.applications.browser.firefox or "")
        then "twilight"
        else "default";
      module = modules.zen-browser.${variant} or {};
      appInfo = userApplication {
        inherit user pkgs config;
        name = "zen-browser";
        kind = "browser";
        resolutionHints = ["zen" "zen-twilight" "zen-beta"];
        debug = true;
      };
    in {
      inherit module;
      inherit
        (appInfo)
        name
        kind
        packageFound
        command
        basename
        identifiers
        isPrimary
        isSecondary
        isRequested
        isPlatformCompatible
        isAllowed
        sessionVariables
        ;
    };
  };
  exports = {inherit mkUserApps;};
in
  exports // {_rootAliases = exports;}
