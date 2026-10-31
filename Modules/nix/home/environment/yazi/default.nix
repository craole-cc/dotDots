{
  apps,
  config,
  lix,
  options,
  paths,
  pkgs,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption mkTrue;
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.attrsets.transformation) filterAttrs mapAttrs';
  inherit (lix.filesystem.access) readDir readFile;
  inherit (lix.filesystem.primitives) concat;
  inherit (lix.strings.predicates) hasSuffix;
  inherit (lix.strings.transformation) removeSuffix;
  inherit (lix.lists.construction) optionals;
  inherit (lix.toolkit.platform) isDarwin;

  dom = "environment";
  mod = "yazi";
  context = mkContext {inherit config dom mod;};
  inherit (context) cfg;

  baseline = let
    root = paths.store.cfg.default + "/${mod}";
    read = stem: let
      content = readFile (concat {inherit root stem;});
    in
      if hasSuffix ".toml" stem
      then fromTOML content
      else content;
  in {
    settings = read "config.toml";
    keymap = read "keymap.toml";
    theme = {};
    initLua = read "init.lua";
    shellWrapperName = "y";

    plugins = let
      pluginsRoot = concat {
        inherit root;
        stem = "plugins";
      };
      plugins =
        filterAttrs
        (name: type: type == "directory" && hasSuffix ".${mod}" name) (readDir pluginsRoot);
    in
      (mapAttrs' (stem: _: {
          name = removeSuffix ".${mod}" stem;
          value = concat {
            root = pluginsRoot;
            inherit stem;
          };
        })
        plugins)
      // {inherit (pkgs.yaziPlugins) ouch;};
    flavors = {};
  };
  names = ["settings" "keymap" "theme" "initLua" "plugins" "flavors" "shellWrapperName"];
in
  mkConfig {
    inherit context;
    options =
      {
        enable = mkEnable {
          inherit context;
          condition = apps.needs mod;
        };
        importConfig = mkTrue "Use the saved Yazi configuration as option defaults.";
      }
      // genAttrs names (name:
        mkOption {
          inherit (options.programs.yazi.${name}) type description;
          default =
            if cfg.importConfig
            then baseline.${name}
            else options.programs.yazi.${name}.default;
        });

    outputs = {
      home.packages = optionals isDarwin [pkgs.yaziPlugins.mactag];
      programs.yazi =
        {inherit (cfg) enable;}
        // genAttrs names (name: cfg.${name});
    };
  }
