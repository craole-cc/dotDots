{lib}: let
  inherit
    (lib.attrsets)
    attrNames
    attrValues
    listToAttrs
    mapAttrs
    optionalAttrs
    ;
  inherit
    (lib.lists)
    concatMap
    concatLists
    elem
    filter
    toList
    unique
    ;
  inherit (lib.packages) getSystem mkPkgs;
  inherit (lib.shells) mkFormatting mkTools mkShells;
  inherit (lib.strings) concatNonEmpty toPascalCase isString toLower;
  inherit (lib.templates) deployTemplates;

  isDisabled = value:
    value
    == null
    || value == false
    || value == {}
    || value == []
    || value == "";
  isEnabled = value: !isDisabled value;

  normalizeEditor = editor: let
    editors = {
      groups = {
        helix = ["helix" "hx"];
        neovim = ["neovim" "nvim"];
        rust-rover = ["idea" "jetbrains" "rust-rover" "rustrover"];
        sublime = ["sublime-text" "sublime"];
        vscode = ["code" "cursor" "vscode-insiders" "vscode" "vscodium" "windsurf"];
        zed = ["zed" "zeditor"];
      };
      known = concatLists (attrValues editors);
    };
  in
    if isDisabled editor
    then {
      enable = false;
      base = false;
      editors = [];
    }
    else if editor == true
    then {
      enable = true;
      base = true;
      editors = [];
    }
    else if isString editor && toLower editor == "all"
    then {
      enable = true;
      base = true;
      editors = editors.known;
    }
    else let
      editors = unique (
        filter
        (e: elem e editors.known)
        (map toLower (toList editor))
      );
    in {
      enable = editors != [];
      base = editors != [];
      inherit editors;
    };

  normalizeFeature = defaults: value:
    if isDisabled value
    then defaults // {enable = false;}
    else if value == true
    then defaults // {enable = true;}
    else defaults // value // {enable = isEnabled (value.enable or true);};

  normalizeVariant = args: let
    raw = optionalAttrs (!isDisabled args) args;
  in {
    base = normalizeFeature {
      enable = true;
      includeMise = false;
    } (raw.base or true);

    rust = let
      base = normalizeFeature {
        enable = false;
        includeToolchain = false;
      } (raw.rust or null);
    in
      base // {enable = base.enable || isEnabled (raw.includeRust or false);};

    web = let
      base = normalizeFeature {
        enable = false;
        includeDeno = false;
        includePrettier = false;
        includeTrunk = false;
      } (raw.web or null);
    in
      base // {enable = base.enable || isEnabled (raw.includeWeb or false);};

    database = let
      base = normalizeFeature {
        enable = false;
        includeMysql = false;
        includePostgres = false;
        includeRedis = false;
        includeSqlite = false;
      } (raw.database or null);
    in
      base // {enable = base.enable || isEnabled (raw.includeDatabase or false);};

    editor = normalizeEditor (raw.editor or null);
  };

  mkEnvVariant = {
    builder,
    variants,
  }:
    mapAttrs (_: args: builder {inherit args;}) variants;

  mkIdeVariant = {
    builder,
    variants,
    editors,
  }:
    listToAttrs (
      concatMap
      (
        variantName:
          map
          (editor: {
            name = concatNonEmpty "" [variantName "With" (toPascalCase editor)];
            value = builder {
              args = variants.${variantName} // {inherit editor;};
            };
          })
          editors
      )
      (attrNames variants)
    );

  mkEnvironment = {
    inputs,
    self,
    pkgs ? mkPkgs {inherit inputs;},
    config ? {},
    extraPackages ? [],
    extraEnv ? {},
  }: let
    variant = normalizeVariant config;
    templates = deployTemplates {inherit pkgs variant;};
    formatting = mkFormatting {inherit inputs self;} variant;
    tools = mkTools ({inherit pkgs;} // variant);
    packages = (
      []
      ++ (attrValues formatting.packages.${getSystem pkgs})
      ++ tools.packages
      ++ extraPackages
    );
    shellHook = "";
    env = {} // tools.env // extraEnv;
  in {
    inherit templates packages;
    inherit (formatting) formatter checks;
    devShells = mkShells {
      inherit inputs;
      default = {inherit packages shellHook env;};
    };
  };
in {
  inherit
    mkEnvironment
    mkEnvVariant
    mkIdeVariant
    ;
}
