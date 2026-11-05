{_, ...}: let
  inherit (_.applications.registry) resolve;
  inherit (_.attrsets.access) attrByPath;
  inherit (_.attrsets.construction) genAttrs;
  inherit (_.attrsets.predicates) isAttrs;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.debug.tracing) tryEval;
  inherit (_.lists.access) head;
  inherit (_.lists.predicates) any isIn;
  inherit (_.lists.transformation) filter;
  inherit (_.schema.packages) selectedPackages;
  inherit (_.sources.modules) mkModule;
  inherit (_.strings.construction) splitString;
  inherit (_.strings.predicates) hasInfix;
  inherit (_.strings.transformation) replaceStrings toLower;

  __exports = rec {
    internal = {
      inherit defaults mkApp mkApps mkPrograms;
      mkHomeApp = mkApp;
      mkHomeApps = mkApps;
      mkHomePrograms = mkPrograms;
    };
    external = {inherit (internal) mkHomeApp mkHomeApps mkHomePrograms;};
  };

  normalizeName = value:
    if value == null
    then null
    else replaceStrings [" " "_"] ["-" "-"] (toLower value);

  normalizeNames = values: map normalizeName values;

  defaults = {
    apps = {
      plasma.aliases = normalizeNames ["kde" "kde-plasma" "plasma6"];

      catppuccin = {
        aliases = normalizeNames ["catppuccin-theme" "catpp"];
        flavors = normalizeNames ["latte" "frappe" "macchiato" "mocha"];
      };

      caelestia.aliases = normalizeNames ["caelestia-shell" "cls"];
      "dux-shell".aliases = normalizeNames [
        "dank"
        "dms"
        "dank-material-shell"
        "dux"
        "dux-shell"
      ];
      "dms-plugin-registry".aliases = normalizeNames [
        "dmsp"
        "dank-plugins"
        "dux-plugins"
      ];
      "hermes-agent".aliases = normalizeNames [
        "hermes"
        "hermes-desktop"
      ];
      "noctalia-shell".aliases = normalizeNames [
        "noctalia"
        "noctalia-dev"
      ];
      nvf.aliases = normalizeNames [
        "nvim"
        "neovim"
      ];
      niri.aliases = normalizeNames [
        "wmNiri"
        "niri-nix"
        "niri"
      ];
    };

    mappings = {
      command = {
        terminal = {
          foot = "feet";
          ghostty = "ghostty";
        };
        browser = {
          zen-twilight = "zen";
          zen-beta = "zen";
        };
        editor = {
          vscode = "code";
          zed = "zeditor";
        };
        launcher = {
          vicinae = "vicinae toggle";
          fuzzel = "pkill fuzzel || fuzzel --list-executables-in-path";
        };
      };
      class = {
        feet = "foot";
        ghostty = "com.mitchellh.ghostty";
        zeditor = "dev.zed.Zed";
        fuzzel = "fuzzel";
        vicinae = "vicinae";
      };
    };

    programs = {
      terminal = {
        primary = "foot";
        secondary = "ghostty";
      };
      browser = {
        primary = "zen";
        secondary = "chromium";
      };
      editor = {
        primary = {
          option = "gui.primary";
          default = "vscode";
        };
        secondary = {
          option = "gui.secondary";
          default = "zed";
        };
      };
      explorer = {
        primary = "yazi";
        secondary = "org.gnome.Nautilus";
      };
      launcher = {
        primary = "vicinae";
        secondary = "fuzzel";
      };
      tui = normalizeNames ["yazi" "btop" "htop" "fend"];
    };
  };

  mkApp = {
    name,
    condition,
    inputs,
    modules,
    context ? {},
    variant ? "default",
  }: let
    cfg = attrByPath ["apps" name] {} defaults;
    names = normalizeNames ([name] ++ (cfg.aliases or []));
    flavors = normalizeNames (cfg.flavors or []);
    variants = mapAttrs (_: normalizeNames) (cfg.variants or {});
    isAllowed = condition ({inherit cfg name names flavors variants;} // context);
    module = mkModule {inherit inputs modules name variant;};
  in {inherit isAllowed module;};

  mkApps = {
    user,
    inputs,
    modules,
    ...
  }: let
    groups = user.packages or (_.schema.packages.resolve {record = user;});
    appsAllowed = normalizeNames (selectedPackages user);
    ai = groups.ai-agent or [];
    ui = user.interface or {};
    de = normalizeName (attrByPath ["desktopEnvironment"] "" ui);

    theme = genAttrs ["light" "dark"] (
      mode: normalizeName ((attrByPath ["style" "theme"] {} ui).${mode} or "")
    );

    panels = groups.bar or [];
    bar =
      if panels == []
      then null
      else normalizeName (head panels);
    selectedPanels = filter (panel: panel != null) (map (value: let
      result = tryEval (resolve {
        inherit value;
        category = "panel";
      });
    in
      if result.success
      then result.value
      else null)
    panels);

    resolveBrowser = value:
      if value == null || value == ""
      then null
      else let
        result = tryEval (resolve {
          value = normalizeName value;
          category = "browser";
        });
      in
        if result.success
        then result.value
        else null;

    browserCandidates =
      filter
      (app: app != null)
      (map resolveBrowser (
        (groups.browser or [])
        ++ appsAllowed
      ));
    zenBrowsers =
      filter
      (app: (app.family or "") == "zen")
      browserCandidates;
    selectedZenBrowser =
      if zenBrowsers == []
      then null
      else head zenBrowsers;

    tty = groups.editor or [];
    hasAnyApp = names: extras: isIn names (appsAllowed ++ normalizeNames extras);
    context = {
      inherit
        appsAllowed
        ai
        bar
        selectedPanels
        theme
        de
        selectedZenBrowser
        hasAnyApp
        tty
        ;
    };

    isDmsShellAllowed = {selectedPanels, ...}:
      any (panel: panel.name == "dms-shell") selectedPanels;

    appSpecs = {
      plasma.condition = {
        names,
        de,
        ...
      }:
        isIn names de;

      catppuccin.condition = {
        name,
        names,
        flavors,
        appsAllowed,
        theme,
        ...
      }:
        isIn names appsAllowed
        || hasInfix (normalizeName name) theme.light
        || hasInfix (normalizeName name) theme.dark
        || isIn flavors [
          theme.light
          theme.dark
        ];

      caelestia.condition = {
        names,
        hasAnyApp,
        bar,
        ...
      }:
        hasAnyApp names [bar];

      "dms-shell".condition = isDmsShellAllowed;
      "dms-plugin-registry".condition = isDmsShellAllowed;

      "hermes-agent".condition = {
        ai,
        names,
        hasAnyApp,
        ...
      }:
        hasAnyApp names ai;

      "noctalia-shell".condition = {
        names,
        hasAnyApp,
        bar,
        ...
      }:
        hasAnyApp names [bar];

      nvf.condition = {
        names,
        hasAnyApp,
        tty,
        ...
      }:
        hasAnyApp names tty;

      "zen-browser" = {
        variant =
          if selectedZenBrowser == null
          then "default"
          else selectedZenBrowser.channel or "default";
        condition = {selectedZenBrowser, ...}:
          selectedZenBrowser != null;
      };
    };
  in
    mapAttrs (
      name: spec:
        mkApp (
          {
            inherit
              context
              name
              inputs
              modules
              ;
          }
          // spec
        )
    )
    appSpecs;

  mkPrograms = {
    host,
    user,
  }: let
    inherit (defaults) mappings programs;
    hostApps = host.applications or {};
    userApps = user.applications or {};
    programDefaults = removeAttrs programs ["tui"];
    rawTerm = normalizeName (
      attrByPath ["terminal" "primary"] (attrByPath [
          "terminal"
          "primary"
        ]
        programs.terminal.primary
        hostApps)
      userApps
    );
    primaryTerminalCmd = attrByPath ["terminal" rawTerm] rawTerm mappings.command;

    getCommand = category: name: let
      n = normalizeName name;
      cmd =
        if category == "browser"
        then
          (resolve {
            value = n;
            inherit category;
          }).exec
        else if category == "editor" && hasInfix "code" n
        then attrByPath ["editor" "vscode"] "code" mappings.command
        else if category == "editor" && hasInfix "zed" n
        then attrByPath ["editor" "zed"] "zeditor" mappings.command
        else attrByPath [category n] n mappings.command;
    in
      if isIn n programs.tui
      then "${primaryTerminalCmd} -e ${cmd}"
      else cmd;

    getClass = command: let
      n = normalizeName command;
    in
      if hasInfix "fuzzel" n
      then "fuzzel"
      else if hasInfix "vicinae" n
      then "vicinae"
      else if hasInfix "yazi" n
      then "yazi"
      else attrByPath [n] n mappings.class;

    resolveProgram = {
      category,
      option,
      default,
    }: let
      userCategory = attrByPath ["applications" category] {} user;
      hostCategory = attrByPath ["applications" category] {} host;
      optionPath = splitString "." option;
      name = normalizeName (
        attrByPath optionPath (attrByPath optionPath default hostCategory) userCategory
      );
      app =
        if category == "browser"
        then
          resolve {
            value = name;
            inherit category;
          }
        else null;
      command =
        if app != null
        then app.exec
        else getCommand category name;
      class =
        if app != null
        then app.names.class or command
        else getClass command;
    in {
      inherit command class;
    };

    mkCategory = category: options:
      mapAttrs (
        name: value: let
          cfg =
            if isAttrs value
            then value
            else {
              option = name;
              default = value;
            };
        in
          resolveProgram {
            inherit category;
            option = cfg.option or name;
            inherit (cfg) default;
          }
      )
      options;
  in
    mapAttrs mkCategory programDefaults // {inherit resolveProgram;};
in
  __exports.internal // {__rootAliases = __exports.external;}
