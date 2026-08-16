{_, ...}: let
  meta = let
    doc = ''
      Application config helpers.
      Provides small helpers that assemble user-facing application module
      metadata from `userApplication` plus selected input modules.
    '';
    functions = {inherit mkUserApp;};
    exports = {
      local = functions;
      alias = functions;
    };
  in {inherit doc exports functions;};

  inherit (_.applications.generators) userApplication;

  mkUserApp = {
    modules,
    pkgs,
    user,
    config,
    moduleName,
    app,
  }: let
    appInfo = userApplication (
      {
        inherit user pkgs config;
        debug = false;
      }
      // app
    );
  in {
    module = modules.${moduleName}.default or {};
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
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
