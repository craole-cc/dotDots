{lib, ...}: let
  inherit (lib.attrsets) attrValues isAttrs mapAttrs;
  inherit (lib.lists) concatLists elem filter toList unique;
  inherit (lib.strings) concatNonEmpty toPascalCase isString toLower;
  inherit (lib.trivial) hasAny isDisabled isEnabled;

  #╔═══════════════════════════════════════════════════════════╗
  #║ Editor                                                    ║
  #╚═══════════════════════════════════════════════════════════╝

  editorGroups = {
    helix = ["helix" "hx"];
    neovim = ["neovim" "nvim"];
    rust-rover = [
      # "idea"
      # "jetbrains"
      "rust-rover"
      "rustrover"
    ];
    sublime = ["sublime-text" "sublime"];
    vscode = [
      "code"
      "cursor"
      "vscode-insiders"
      "vscode"
      "vscodium"
      "windsurf"
    ];
    zed = ["zed" "zeditor"];
  };

  knownEditors = concatLists (attrValues editorGroups);

  #? toPascalCase handles the hyphen: rust-rover → RustRover
  editorShellName = tier: editor:
    concatNonEmpty "" [tier "With" (toPascalCase editor)];

  normalizeEditor = editor: let
    mkGroups = resolved: mapAttrs (_: members: hasAny members resolved) editorGroups;

    resolve = input:
      unique (filter (e: elem e knownEditors) (map toLower (toList input)));

    mkResult = resolved:
      {
        enable = true;
        base = true;
        editors = resolved;
      }
      // mkGroups resolved;
  in
    if isDisabled editor
    then
      {
        enable = false;
        base = false;
        editors = [];
      }
      // mkGroups []
    else if isEnabled editor
    then mkResult []
    else if isString editor && toLower editor == "all"
    then mkResult knownEditors
    else mkResult (resolve editor);

  #╔═══════════════════════════════════════════════════════════╗
  #║ Features                                                  ║
  #╚═══════════════════════════════════════════════════════════╝

  normalizeFeature = defaults: value:
    if isDisabled value
    then defaults // {enable = false;}
    else if isAttrs value
    then defaults // value // {enable = isEnabled (value.enable or true);}
    else if isEnabled value
    then defaults // {enable = true;}
    else defaults;

  normalizeAi = value: let
    defaults = {
      enable = false;
      includeCodex = false;
      includeClaude = false;
      includeGemini = false;
      includeHermes = false;
      includeOpenClaw = false;
    };

    preset =
      if value == "minimal"
      then {
        enable = true;
        includeCodex = true;
        includeGemini = true;
      }
      else if value == "default"
      then {
        enable = true;
        includeCodex = true;
        includeClaude = true;
        includeGemini = true;
      }
      else if value == "full"
      then {
        enable = true;
        includeCodex = true;
        includeClaude = true;
        includeGemini = true;
        includeHermes = true;
        includeOpenClaw = true;
      }
      else if isEnabled value
      then {
        enable = true;
        includeCodex = true;
        includeClaude = true;
      }
      else {};
  in
    if isAttrs value
    then
      defaults
      // preset
      // value
      // {enable = isEnabled (value.enable or true);}
    else defaults // preset;

  normalizeVariant = raw: {
    __variantName = raw.__variantName or null;

    common = normalizeFeature {
      enable = true;
    } (raw.common or true);

    extra = let
      defaults = {
        enable = false;
        includeMise = false;
        includeFetch = false;
        includeGitTools = false;
        includeFileTools = false;
        includeRustScript = false;
      };
    in
      if isEnabled (raw.extra or null)
      then mapAttrs (_: _: true) defaults
      else normalizeFeature defaults (raw.extra or null);

    ai = normalizeAi (raw.ai or null);

    rust = let
      base = normalizeFeature {
        enable = false;
        channel = "nightly";
        minimal = false;
        includeDocs = false;
        includeAnalyzer = false;
        includeWeb = false;
        includeLeptos = false;
        includeExtra = false;
        extraTargets = [];
        extraExtensions = [];
      } (raw.rust or null);
    in
      base
      // {enable = base.enable || isEnabled (raw.includeRust or false);};

    web = let
      base = normalizeFeature {
        enable = false;
        includeDeno = false;
        includePrettier = false;
        includeTrunk = false;
      } (raw.web or null);
    in
      base
      // {enable = base.enable || isEnabled (raw.includeWeb or false);};

    database = let
      base = normalizeFeature {
        enable = false;
        includeMysql = false;
        includePostgres = false;
        includeRedis = false;
        includeSqlite = false;
      } (raw.database or null);
    in
      base
      // {enable = base.enable || isEnabled (raw.includeDatabase or false);};

    editor = normalizeEditor (raw.editor or null);
  };
in {
  inherit
    editorGroups
    knownEditors
    editorShellName
    normalizeVariant
    normalizeFeature
    normalizeAi
    normalizeEditor
    ;
}
