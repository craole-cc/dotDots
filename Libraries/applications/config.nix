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
    noctalia-shell = let
      module = modules.noctalia-shell.default or {};
      cfg = userApplicationConfig {
        inherit user pkgs config;
        name = "noctalia-shell";
        kind = "bar";
        resolutionHints = ["noctalia" "noctalia-dev"];
        debug = true;
      };
    in
      cfg // {inherit module;};

    nvf = let
      module = modules.nvf.default or {};
      cfg = userApplicationConfig {
        inherit user pkgs config;
        name = "nvf";
        kind = "editor";
        category = "tty";
        resolutionHints = ["nvim" "neovim"];
        debug = true;
      };
    in
      cfg // {inherit module;};

    zen-browser = let
      variant =
        if hasInfix "twilight" (user.applications.browser.firefox or "")
        then "twilight"
        else "default";
      module = modules.zen-browser.${variant} or {};
      cfg = userApplicationConfig {
        inherit user pkgs config;
        name = "zen-browser";
        kind = "browser";
        resolutionHints = ["zen" "zen-twilight" "zen-beta"];
        debug = true;
      };
    in
      cfg // {inherit module;};
  };
  exports = {inherit mkUserApps;};
in
  exports // {_rootAliases = exports;}
