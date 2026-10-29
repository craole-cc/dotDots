{_, ...}: let
  inherit (_.applications.registry) resolve;
  inherit (_.attrsets.access) attrByPath attrValues;
  inherit (_.lists.construction) concatLists genList;
  inherit (_.attrsets.construction) genAttrs;
  inherit (_.lists.transformation) unique;
  inherit (_.attrsets.aggregation) recursiveUpdate;
  inherit (_.strings.predicates) hasInfix;
  inherit (_.strings.transformation) toLower;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.lists.access) head length;
  inherit (_.lists.transformation) imap0;
  inherit (_.schema.packages) merge policyFields roleView toApplications;

  __exports = {
    internal = {inherit defaults uiDefaults mkApplications;};
    external = {
      mkSchemaApplications = mkApplications;
    };
  };

  # ── Defaults ────────────────────────────────────────────────────────────────

  defaults = {
    browser = ["zen-twilight" "chromium"];
    terminal = ["kitty" "ghostty"];
    editor = ["helix" "neovim"];
    ide = ["vscode" "zed"];
    launcher = ["vicinae" "fuzzel"];
    explorer = ["yazi" "nautilus"];
    ai-agent = [];
    bar = [];
    prompt = ["starship"];
    allowed = [];
  };

  uiDefaults = {
    launcher = {
      pri = "vicinae";
      sec = "vicinae";
    };
    terminal = {
      pri = "kitty";
      sec = "ghostty";
    };
    explorer = {
      pri = "doublecmd";
      sec = "yazi";
    };
    browser = {
      pri = "zen-twilight";
      sec = "chromium";
    };
    editor = {
      pri = "vscode";
      sec = "helix";
    };
  };

  # ── Command resolution ───────────────────────────────────────────────────────
  # Maps app names to the actual binary command to run.

  commandMap = {
    browser = {
      "zen-twilight" = "zen";
      "zen-beta" = "zen";
      "zen" = "zen";
      "chromium" = "chromium";
      "firefox" = "firefox";
      "brave" = "brave";
      "vivaldi" = "vivaldi";
      "floorp" = "floorp";
      "microsoft-edge" = "microsoft-edge";
      "google-chrome" = "google-chrome-stable";
    };
    terminal = {
      "foot" = "feet";
      "ghostty" = "ghostty";
      "kitty" = "kitty";
      "alacritty" = "alacritty";
      "wezterm" = "wezterm";
      "warp-terminal" = "warp-terminal";
      "rio" = "rio";
    };
    editor = {
      "helix" = "hx";
      "neovim" = "nvim";
      "nvim" = "nvim";
      "vscode" = "code";
      "vscode-fhs" = "code";
      "vscode-insiders" = "code-insiders";
      "code-insiders" = "code-insiders";
      "vscodium" = "codium";
      "zed" = "zeditor";
      "zed-editor-fhs" = "zeditor";
      "zeditor" = "zeditor";
      "vim" = "vim";
      "nano" = "nano";
      "emacs" = "emacs";
      "sublime" = "subl";
    };
    launcher = {
      "vicinae" = "vicinae toggle";
      "fuzzel" = "pkill fuzzel || fuzzel --list-executables-in-path";
      "wofi" = "wofi";
      "rofi" = "rofi";
      "tofi" = "tofi";
      "dmenu" = "dmenu";
      "ulauncher" = "ulauncher";
    };
    explorer = {
      "yazi" = "yazi";
      "doublecmd" = "doublecmd";
      "nautilus" = "org.gnome.Nautilus";
      "dolphin" = "dolphin";
      "thunar" = "thunar";
      "nemo" = "nemo";
    };
    bar = {
      "waybar" = "waybar";
      "caelestia" = "caelestia";
      "noctalia" = "noctalia";
      "ags" = "ags";
      "eww" = "eww";
      "yambar" = "yambar";
    };
  };

  # ── Class resolution ─────────────────────────────────────────────────────────

  classMap = {
    "zen" = "zen";
    "chromium" = "chromium";
    "firefox" = "firefox";
    "brave" = "brave";
    "vivaldi" = "vivaldi";
    "floorp" = "floorp";
    "microsoft-edge" = "microsoft-edge";
    "google-chrome-stable" = "google-chrome";
    "feet" = "foot";
    "ghostty" = "com.mitchellh.ghostty";
    "kitty" = "kitty";
    "alacritty" = "Alacritty";
    "wezterm" = "org.wezfurlong.wezterm";
    "warp-terminal" = "dev.warp.Warp";
    "hx" = "Helix";
    "nvim" = "nvim";
    "code" = "code";
    "code-insiders" = "code - Insiders";
    "codium" = "VSCodium";
    "zeditor" = "dev.zed.Zed";
    "vim" = "vim";
    "vicinae" = "vicinae";
    "fuzzel" = "fuzzel";
    "wofi" = "wofi";
    "rofi" = "rofi";
    "yazi" = "yazi";
    "doublecmd" = "doublecmd";
    "org.gnome.Nautilus" = "org.gnome.Nautilus";
    "dolphin" = "dolphin";
    "thunar" = "thunar";
  };

  legacyCommand = category: name: let
    n = toLower name;
  in
    attrByPath [category n] n commandMap;

  legacyClass = command: let
    n = toLower command;
  in
    if hasInfix "fuzzel" n
    then "fuzzel"
    else if hasInfix "vicinae" n
    then "vicinae"
    else if hasInfix "yazi" n
    then "yazi"
    else if hasInfix "ghostty" n
    then "com.mitchellh.ghostty"
    else if hasInfix "zeditor" n
    then "dev.zed.Zed"
    else if hasInfix "nautilus" n
    then "org.gnome.Nautilus"
    else classMap.${n} or n;

  getCommand = category: name:
    (getMeta category name).exec or (legacyCommand category name);

  # A package group is an ordering chosen by the caller, rather than a
  # registry category. Unknown names still retain executable metadata.
  getMeta = _category: name: let
    result = builtins.tryEval (resolve {
      value = name;
    });
  in
    if result.success
    then result.value
    else {};

  getClass = category: name: let
    command = getCommand category name;
    meta = getMeta category name;
  in
    meta.names.class or (legacyClass command);

  scratchpadCommand = category: command:
    if category == "browser"
    then "${command} --new-window about:blank"
    else command;

  mkEntry = category: name: let
    meta = getMeta category name;
    command = getCommand category name;
  in {
    name = meta.name or name;
    inherit command;
    class = getClass category name;
    needsTerminal = meta.needsTerminal or false;
    wrap = meta.wrap or {};
    launch =
      (meta.launch or {})
      // {
        scratchpad = meta.launch.scratchpad or (scratchpadCommand category command);
        private =
          meta.launch.private or (
            if category != "browser"
            then null
            else if (meta.family or "") == "chromium"
            then "${command} --incognito --new-window about:blank"
            else if (meta.family or "") == "firefox" || (meta.family or "") == "zen"
            then "${command} --private-window about:blank"
            else null
          );
      };
  };

  # ── Resolution ───────────────────────────────────────────────────────────────

  mkApplications = {
    host,
    user ? {},
    selections ? null,
  }: let
    userProtocol = (user.interface or {}).displayProtocol or null;
    hostProtocol = (host.interface or {}).displayProtocol or null;
    protocol =
      if userProtocol != null
      then userProtocol
      else hostProtocol;

    # Defaults are ordinary selections, so explicit API lists can replace them.
    # Schema users already contain the merged host/profile/principal selection;
    # using their canonical lists avoids reinterpreting the compatibility roles
    # as fresh declarations and promoting defaults back into an explicit list.
    selection =
      if selections != null
      then {packages = selections;}
      else merge host user;
    packages = _.schema.packages.resolve {
      record = merge {packages = defaults;} selection;
      inherit protocol;
    };
    raw = toApplications {
      inherit packages;
      legacy = recursiveUpdate (host.applications or {}) (user.applications or {});
    };
    entries = mapAttrs (group: names: let
      category =
        if group == "ai-agent"
        then "ai"
        else if group == "ide"
        then "editor"
        else group;
    in
      map (mkEntry category) names) (removeAttrs packages policyFields);
    # Missing positions reuse the first entry and its workspace identity.
    # Package selections stay unpadded; both compositors consume this view.
    scratchpadSlots = selected: let
      indexed = imap0 (index: entry: entry // {scratchpadSlot = index + 1;}) selected;
    in
      if indexed == []
      then []
      else
        indexed
        ++ genList (_index: head indexed) (
          if length indexed < 3
          then 3 - length indexed
          else 0
        );
    normalScratchpads = genAttrs ["terminal" "browser" "explorer" "editor" "ide" "ai-agent" "media"] (
      group: scratchpadSlots (entries.${group} or [])
    );
    scratchpads =
      normalScratchpads
      // {
        browserPrivate = map (entry:
          entry
          // {
            launch = entry.launch // {scratchpad = entry.launch.private;};
          })
        normalScratchpads.browser;
      };
    legacyGroup = name: roleView (entries.${name} or []);
    # Host requirements remain installed even when a user's ordered preference
    # replaces the host group. Coding selects toolchains in its own module.
    requiredPackages = unique (concatLists (attrValues (removeAttrs
      (_.schema.packages.resolve {
        record = host;
        inherit protocol;
      })
      (policyFields ++ ["coding"]))));
  in
    entries
    // {
      inherit packages requiredPackages scratchpads;
      # Named positions are a compatibility view for existing shortcuts. The
      # application contract above retains every entry of every group.
      legacy = {
        inherit raw;
        ai = legacyGroup "ai-agent";
        browser = legacyGroup "browser";
        terminal = legacyGroup "terminal";
        launcher = legacyGroup "launcher";
        explorer = legacyGroup "explorer";
        editor =
          legacyGroup "ide"
          // {
            tty = legacyGroup "editor";
            gui = legacyGroup "ide";
          };
        bar.primary =
          if entries.bar == []
          then mkEntry "bar" "waybar"
          else head entries.bar;
        inherit (raw) prompt allowed;
      };
    };
in
  __exports.internal // {__rootAliases = __exports.external;}
