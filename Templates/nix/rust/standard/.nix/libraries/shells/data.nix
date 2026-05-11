{
  lib,
  paths,
  ...
}: let
  inherit
    (lib.attrsets)
    attrValues
    mapAttrs
    ;
  inherit
    (lib.lists)
    concatLists
    elem
    filter
    toList
    unique
    ;
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

  #╔═══════════════════════════════════════════════════════════╗
  #║ Normalizers                                               ║
  #╚═══════════════════════════════════════════════════════════╝

  normalizeEditor = editor: let
    mkGroups = resolved: mapAttrs (_: members: hasAny members resolved) editorGroups;
    mkResult = resolved:
      {
        enable = resolved != [];
        base = resolved != [];
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
    else if editor == true
    then
      {
        enable = true;
        base = true;
        editors = [];
      }
      // mkGroups []
    else if isString editor && toLower editor == "all"
    then
      {
        enable = true;
        base = true;
        editors = knownEditors;
      }
      // mkGroups knownEditors
    else let
      resolved = unique (
        filter (e: elem e knownEditors) (map toLower (toList editor))
      );
    in
      mkResult resolved;

  normalizeFeature = defaults: value:
    if isDisabled value
    then defaults // {enable = false;}
    else if value == true
    then defaults // {enable = true;}
    else defaults // value // {enable = isEnabled (value.enable or true);};

  normalizeAi = value:
    if isDisabled value
    then {
      enable = false;
      includeCodex = false;
      includeClaude = false;
      includeHermes = false;
      includeOpenClaw = false;
    }
    else if value == "minimal"
    then {
      enable = true;
      includeCodex = true;
      includeClaude = false;
      includeHermes = false;
      includeOpenClaw = false;
    }
    else if value == true || value == "default"
    then {
      enable = true;
      includeCodex = true;
      includeClaude = true;
      includeHermes = false;
      includeOpenClaw = false;
    }
    else if value == "full"
    then {
      enable = true;
      includeCodex = true;
      includeClaude = true;
      includeHermes = true;
      includeOpenClaw = true;
    }
    else
      normalizeFeature {
        enable = false;
        includeCodex = false;
        includeClaude = false;
        includeHermes = false;
        includeOpenClaw = false;
      }
      value;

  normalizeVariant = raw: {
    base = normalizeFeature {
      enable = true;
      includeMise = false;
    } (raw.base or true);

    ai = normalizeAi (raw.ai or null);

    rust = let
      base = normalizeFeature {
        enable = false;
        channel = "nightly";
        minimal = false;
        includeDocs = false;
        extraTargets = [];
        extraExtensions = [];
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
