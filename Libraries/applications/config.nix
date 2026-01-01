{
  _,
  lib,
  ...
}: let
  inherit (lib.strings) hasInfix;
  inherit (_.applications.generators) userApplicationConfig;

  mkUserApps = {
    modules,
    pkgs,
    user,
    config,
  }: {
    noctalia-shell =
      userApplicationConfig {
        inherit user pkgs config;
        name = "noctalia-shell";
        kind = "bar";
        resolutionHints = ["noctalia" "noctalia-dev"];
        debug = true;
      }
      // rec {
        variant = "default";
        module = modules.noctalia-shell.${variant} or {};
      };

    nvf =
      userApplicationConfig {
        inherit user pkgs config;
        name = "nvf";
        kind = "editor";
        category = "tty";
        resolutionHints = ["nvim" "neovim"];
        debug = true;
      }
      // {module = modules.nvf.default or {};};

    zen-browser =
      userApplicationConfig {
        inherit user pkgs config;
        name = "zen-browser";
        kind = "browser";
        resolutionHints = ["zen" "zen-twilight" "zen-beta"];
        debug = true;
      }
      // rec {
        variant =
          if hasInfix "twilight" (user.applications.browser.firefox or "")
          then "twilight"
          else "default";
        module = modules.zen-browser.${variant} or {};
      };
  };
  exports = {inherit mkUserApps;};
in
  exports // {_rootAliases = exports;}
