{
  lix,
  inputs,
  pkgs,
  cfg,
  context,
  paths,
  ...
} @ args: let
  inherit (lix.applications.editors) mkVSCodeFeature mkVSCodeSubFeature normalizeSettings;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.attrsets.construction) genAttrs genAttrs' listToAttrs nameValuePair;
  inherit (lix.attrsets.transformation) mapAttrs mapAttrsToList;
  inherit (lix.attrsets.resolution) parseVscodeExt vscodePackage;
  inherit (lix.filesystem.access) readFileType;
  inherit (lix.filesystem.traversal) importAllNamed readJSON;
  inherit (lix.lists.aggregation) concatMap;
  inherit (lix.content.fallback) orDefault;
  inherit (lix.lists.construction) optional optionals;
  inherit (lix.lists.predicates) any elem;
  inherit (lix.lists.transformation) filter flatten uniqueStrings;
  inherit (lix.modules.construction) mkDefault mkMerge mkOverride;
  inherit (lix.modules.evaluation) evalModules;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.strings.predicates) hasInfix hasPrefix;
  inherit (lix.types.combinators) listOf submodule;
  inherit (lix.types.predicates) isAttrs isList isPath isString;
  inherit (lix.types.primitives) package;

  baseline = let
    level = 1500;
    root = paths.store.cfg.default;
    files = let
      targets = {
        extensions = [];
        keybindings = [];
        settings = {};
      };
      names = attrNames targets;
      json = genAttrs names (name:
        readJSON {
          inherit root;
          stem = ["vscode" "${name}.json"];
          optional = true;
        });
      getOr = name:
        orDefault {
          content = json.${name};
          default = targets.${name};
        };
    in
      genAttrs names getOr;
  in
    files // {inherit root level;};

  collectExtensionIds = data:
    if isList data
    then
      map
      (entry:
        if isString entry
        then entry
        else entry.identifier.id or (throw "extensions.json: entry has no identifier.id"))
      data
    else [];

  # Explicit dotted keys mark complete settings, including object values.
  # Share these boundaries so another entry can use the same setting nested.
  collectSettingNames = prefix: value:
    if !isAttrs value
    then []
    else if (value._type or null) == "vscode-setting"
    then [prefix]
    else if elem prefix (attrNames baseline.settings)
    then []
    else if value ? _type && value._type == "merge"
    then concatMap (collectSettingNames prefix) value.contents
    else if value ? _type && elem value._type ["if" "override" "order"]
    then collectSettingNames prefix value.content
    else
      concatMap (key: let
        name =
          if prefix == ""
          then key
          else "${prefix}.${key}";
      in
        if prefix == "" && hasPrefix "[" key
        then collectSettingNames "" value.${key}
        else if hasInfix "." key
        then [name]
        else collectSettingNames name value.${key}) (attrNames value);

  collectEntrySettingNames = tree:
    if !isAttrs tree
    then []
    else if tree ? settings || tree ? userSettings
    then
      collectSettingNames "" (tree.settings or {})
      ++ collectSettingNames "" (tree.userSettings or {})
    else concatMap (key: collectEntrySettingNames tree.${key}) (attrNames tree);

  feature = let
    entries = [./ai ./app ./doc ./lang ./ui];

    sets = let
      load = path: let
        mkFeature = mkFeatureFor path;
        loaded = import path (
          args // {inherit mkDefault mkMerge mkVSCodeFeature mkVSCodeSubFeature mkSubFeature mkFeature;}
        );
      in
        if loaded ? feature
        then loaded
        else mkFeature loaded;
    in
      map load entries;

    readEntries = dir: removeAttrs (importAllNamed {inherit dir args;}).value ["default"];

    names = uniqueStrings (
      attrNames baseline.settings
      ++ concatMap (dir: collectEntrySettingNames (readEntries dir)) entries
    );
  in {inherit readEntries sets names;};
  settingNames = feature.names;

  mkSubFeature = {
    stem ? "entry",
    name ? stem,
    description ? stem,
    enable ? true,
    extensions ? [],
    settings ? {},
    userSettings ? {},
    keybindings ? [],
    options ? {},
  }:
    {
      inherit name description enable options;
      owned = {
        settings = attrNames (normalizeSettings {
          inherit settings userSettings settingNames;
        });
        inherit keybindings extensions;
      };
    }
    // mkVSCodeSubFeature {
      inherit enable extensions settings userSettings keybindings settingNames;
    };

  mkSubFeatures = dir: let
    entries = feature.readEntries dir;
    collect = stem: entry: let
      isConfig =
        isAttrs entry
        && any (name: entry ? ${name})
        ["enable" "extensions" "settings" "userSettings" "keybindings" "options"];
    in
      optional isConfig (mkSubFeature ({inherit stem;} // entry))
      ++ optionals (isAttrs entry && !isConfig) (
        flatten (mapAttrsToList collect entry)
      );
  in
    flatten (mapAttrsToList collect entries);

  mkFeatureFor = path: {
    name ? null,
    description ? null,
    meta ? {},
    default ? true,
    entries ? null,
    features ? null,
    # options ? {}, # TODO: never used or passed
  }: let
    resolved = {
      name =
        if name != null
        then name
        else meta.name or (throw "group at ${toString path} needs 'name' or 'meta.name'");

      description =
        if description != null
        then description
        else meta.description or resolved.name;

      dir =
        if readFileType path == "directory"
        then path
        else dirOf path;

      entries =
        if entries != null
        then
          if isPath entries
          then mkSubFeatures entries
          else map mkSubFeature entries
        else if features != null
        then map mkSubFeature features
        else mkSubFeatures resolved.dir;
    };

    extract = target:
      uniqueStrings (
        concatMap (entry: entry.owned.${target} or []) resolved.entries
      );
  in
    (genAttrs ["extensions" "settings"] extract)
    // {keybindings = concatMap (entry: entry.owned.keybindings) resolved.entries;}
    // {
      inherit (resolved) name description;
      options =
        (
          listToAttrs (
            map (entry: {
              inherit (entry) name;
              value = mkEnable {
                inherit context;
                condition = entry.enable;
              };
            })
            resolved.entries
          )
        )
        // {
          enable = mkEnable {
            inherit context;
            condition = default;
          };
        };

      config =
        {enable = default;}
        // genAttrs' resolved.entries
        (entry: nameValuePair entry.name entry.enable);

      feature = config: let
        enable = config.enable or false;
        entries =
          filter
          (entry: enable && (config.${entry.name} or entry.enable))
          resolved.entries;
      in
        mkVSCodeFeature {
          inherit pkgs inputs enable;
          extensions = uniqueStrings (concatMap (entry: entry.extensions or []) entries);
          userSettings = mkMerge (map normalizeSettings entries);
          keybindings = concatMap (entry: entry.keybindings or []) entries;
        };
    };

  module = {
    options = {
      features = mkOption {
        type = submodule {
          options = listToAttrs (
            map (group: {
              inherit (group) name;
              value = mkOption {
                type = submodule {inherit (group) options;};
                default = group.config;
                inherit (group) description;
              };
            })
            feature.sets
          );
        };
        default = {};
        description = "VS Code feature groups";
      };
    };

    output =
      map
      (group: group.feature cfg.features.${group.name})
      feature.sets;
  };

  profile = let
    # Nix entries own their declarations even when disabled. The JSON files
    # supply only settings and bindings that have not moved to an entry yet.
    extensions = uniqueStrings (concatMap (set: set.extensions or []) feature.sets);
    settings = uniqueStrings (concatMap (set: set.settings or []) feature.sets);
    keybindings = concatMap (set: set.keybindings or []) feature.sets;
    learn = name: let
      data = baseline.${name} or null;
    in
      if data == null
      then {}
      else if name == "extensions"
      then
        mkOverride baseline.level (
          map
          (id: let
            parsed = parseVscodeExt id;
          in
            vscodePackage {
              inherit pkgs inputs;
              entry = id;
              default =
                throw "Required VS Code extension '${
                  parsed.publisher
                }.${
                  parsed.name
                }' (from extensions.json) was not found in the configured catalogues.";
            })
          (filter (id: !(elem id extensions)) (collectExtensionIds data))
        )
      else if isList data
      then
        mkOverride baseline.level (
          filter (binding: !(elem binding keybindings)) data
        )
      else mapAttrs (_: mkOverride baseline.level) (removeAttrs data settings);

    options = {
      userSettings = mkOption {
        inherit (args.json) type;
        default = {};
      };
      keybindings = mkOption {
        default = [];
        type = listOf args.json.type;
      };
      extensions = mkOption {
        default = [];
        type = listOf package;
      };
    };

    config = mkMerge (
      module.output
      ++ optional (cfg.importJSON or false) {
        extensions = learn "extensions";
        keybindings = learn "keybindings";
        userSettings = learn "settings";
      }
    );

    modules = evalModules {modules = [{inherit options config;}];};
    output = modules.config;
  in {inherit options config modules output;};
in {
  inherit (module) options;
  inherit (profile) output;
}
