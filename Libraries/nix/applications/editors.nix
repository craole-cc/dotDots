{_, ...}: let
  inherit (_.attrsets.resolution) parseVscodeExt vscodePackage;
  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.aggregation) mergeSafe;
  inherit (_.attrsets.construction) optionalAttrs;
  inherit (_.lists.construction) optionals;
  inherit (_.lists.aggregation) foldl';
  inherit (_.lists.predicates) elem;
  inherit (_.strings.predicates) hasInfix hasPrefix;
  inherit (_.types.predicates) isAttrs isDerivation;

  __exports = {
    internal = {
      inherit
        mkVSCodeFeature
        mkVSCodeSubFeature
        mkHelixFeature
        mkNeovimFeature
        normalizeSettings
        flattenVSCodeSetting
        mkVSCodeSetting
        ;
    };
    external = __exports.internal;
  };

  # Accept both `settings` (user-facing alias) and `userSettings` (canonical)
  # and normalize to `userSettings`.
  #
  # `userSettings` is the base, `settings` the override. `mergeSafe` deep-merges
  # plain attrsets, but treats module-system values (`mkMerge`, `mkIf`,
  # `mkOverride`, option declarations, …) as atomic. A plain empty `{}` on
  # either side is the identity — so a feature layer passing
  # `userSettings = mkMerge [...]` plus the default `settings = {}` keeps the
  # accumulated module value intact (this is what Option B of `mergeSafe`'s
  # predicate fixes).
  #
  # No `!= {}` comparison, so `settings = mkMerge [...]` doesn't throw.
  normalizeSettings = {
    settings ? {},
    userSettings ? {},
    settingNames ? [],
    ...
  }: let
    flatten = flattenVSCodeSetting {inherit settingNames;};
  in
    mergeSafe [(flatten userSettings) (flatten settings)];

  # Mark a complete setting value when its object shape resembles a namespace.
  mkVSCodeSetting = content: {
    _type = "vscode-setting";
    inherit content;
  };

  # Setting names identify where namespaces end and JSON object values begin.
  # Explicit dotted keys also mark complete settings. Language override blocks
  # contain another settings map; arrays and setting values stay intact.
  # A string prefix remains supported for existing callers.
  flattenVSCodeSetting = context: let
    options =
      if isAttrs context
      then context
      else {prefix = context;};
    settingNames = options.settingNames or [];
    unwrap = value:
      if !isAttrs value
      then value
      else if (value._type or null) == "vscode-setting"
      then value.content
      else if elem (value._type or null) ["if" "override" "order"]
      then value // {content = unwrap value.content;}
      else if (value._type or null) == "merge"
      then value // {contents = map unwrap value.contents;}
      else value;
    flatten = prefix: value:
      if isAttrs value && (value._type or null) == "vscode-setting"
      then {"${prefix}" = value.content;}
      else if prefix != "" && elem prefix settingNames
      then {"${prefix}" = unwrap value;}
      else if isAttrs value && value ? _type && elem value._type ["merge" "if" "override" "order"]
      then
        value
        // (
          if value._type == "merge"
          then {contents = map (flatten prefix) value.contents;}
          else {content = flatten prefix value.content;}
        )
      else if isAttrs value && attrNames value != []
      then
        foldl' (
          result: key: let
            name =
              if prefix == ""
              then key
              else "${prefix}.${key}";
            setting =
              if prefix == "" && hasPrefix "[" key
              then {"${key}" = flatten "" value.${key};}
              else if hasInfix "." key
              then {"${name}" = unwrap value.${key};}
              else flatten name value.${key};
          in
            mergeSafe [result setting]
        ) {} (attrNames value)
      else if prefix == ""
      then value
      else {"${prefix}" = value;};
  in
    flatten (options.prefix or "");

  mkVSCodeFeature = {
    extensions,
    settings ? {},
    userSettings ? {},
    keybindings ? [],
    pkgs,
    inputs,
    ...
  } @ args: let
    enable = args.enable or (args.enabled or false);
    effectiveSettings = normalizeSettings {
      inherit settings userSettings;
      settingNames = args.settingNames or [];
    };
  in
    {
      extensions = optionals enable (
        map (
          extension:
            if isDerivation extension
            then extension
            else let
              identifier = parseVscodeExt extension;
            in
              vscodePackage {
                inherit pkgs inputs;
                entry = extension;
                default = throw "Required VS Code extension '${identifier.publisher}.${identifier.name}' was not found in the configured extension catalogues.";
              }
        )
        extensions
      );
      keybindings = optionals enable keybindings;
    }
    // optionalAttrs enable {userSettings = effectiveSettings;};

  mkVSCodeSubFeature = {
    extensions ? [],
    settings ? {},
    userSettings ? {},
    keybindings ? [],
    ...
  } @ args: let
    effectiveSettings = normalizeSettings {
      inherit settings userSettings;
      settingNames = args.settingNames or [];
    };
  in {
    inherit extensions keybindings;
    inherit effectiveSettings; # or: userSettings = effectiveSettings;
  };
  # mkVSCodeSubFeature = {
  #   extensions ? [],
  #   settings ? {},
  #   userSettings ? {},
  #   keybindings ? [],
  #   ...
  # } @ args: let
  #   enable = args.enable or (args.enabled or false);
  #   effectiveSettings = normalizeSettings {
  #     inherit settings userSettings;
  #     settingNames = args.settingNames or [];
  #   };
  # in
  #   {
  #     extensions = optionals enable extensions;
  #     keybindings = optionals enable keybindings;
  #   }
  #   // optionalAttrs enable {userSettings = effectiveSettings;};

  mkHelixFeature = {
    enable,
    languages ? {},
    themes ? {},
  }:
    optionalAttrs enable {inherit languages themes;};

  mkNeovimFeature = {
    enable,
    plugins ? [],
    extraConfig ? "",
  }:
    optionalAttrs enable {inherit plugins extraConfig;};
in
  __exports.internal // {__rootAliases = __exports.internal;}
