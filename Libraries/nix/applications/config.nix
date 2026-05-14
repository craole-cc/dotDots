{ _, ... }:
let
  meta =
    let
      doc = ''
        Application config helpers.
        Provides small helpers that assemble user-facing application module
        metadata from `userApplication` plus selected input modules.
      '';
      functions = { inherit mkUserApp mkUserApps; };
      exports = {
        local = functions;
        alias = functions;
      };
    in
    {
      inherit doc exports functions;
    };

  inherit (_.applications.generators) userApplication;
  inherit (_.strings.predicates) hasInfix;
  mkUserApp =
    {
      modules,
      pkgs,
      user,
      config,
      moduleName,
      app,
    }:
    let
      appInfo = userApplication (
        {
          inherit user pkgs config;
          debug = false;
        }
        // app
      );
    in
    {
      module = modules.${moduleName}.default or { };
      inherit (appInfo)
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

  mkUserApps =
    {
      modules,
      pkgs,
      user,
      config,
    }:
    {
      noctalia-shell = mkUserApp {
        inherit
          modules
          pkgs
          user
          config
          ;
        moduleName = "noctalia-shell";
        app = {
          name = "noctalia-shell";
          kind = "bar";
          customCommand = "noctalia";
          resolutionHints = [
            "noctalia"
            "noctalia-dev"
          ];
        };
      };

      nvf = mkUserApp {
        inherit
          modules
          pkgs
          user
          config
          ;
        moduleName = "nvf";
        app = {
          name = "nvf";
          kind = "editor";
          customCommand = "nvim";
          category = "tty";
          resolutionHints = [
            "nvim"
            "neovim"
          ];
        };
      };

      zen-browser =
        let
          variant = if hasInfix "twilight" (user.applications.browser.firefox or "") then "twilight" else "default";
          appInfo = userApplication {
            inherit user pkgs config;
            name = "zen-browser";
            kind = "browser";
            customCommand = "zen";
            resolutionHints = [
              "zen"
              "zen-twilight"
              "zen-beta"
            ];
            debug = false;
          };
        in
        {
          module = modules.zen-browser.${variant} or { };
          inherit (appInfo)
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
in
meta.exports.local
// {
  __docs = meta.doc;
  __rootAliases = meta.exports.alias;
}
