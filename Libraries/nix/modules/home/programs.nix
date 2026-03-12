{
  _,
  lib,
  ...
}: let
  # inherit (_.inputs.modules) mkModule homeModules;
  inherit (_.inputs.modules) mkModule;
  inherit (_.lists.predicates) isIn;
  inherit (lib.attrsets) attrByPath isAttrs mapAttrs removeAttrs;
  inherit (lib.strings) hasInfix splitString toLower;

  exports = rec {
    internal = {
      inherit defaults mkApp mkApps mkPrograms;
      mkHomeApp = mkApp;
      mkHomeApps = mkApps;
      mkHomePrograms = mkPrograms;
    };
    external = {
      inherit (internal) mkHomeApp mkHomeApps mkHomePrograms;
    };
  };

  normalizeName = value:
    if value == null
    then null
    else builtins.replaceStrings [" " "_"] ["-" "-"] (toLower value);

  normalizeNames = values: map normalizeName values;

  defaults = {
    apps = {
      plasma.aliases = normalizeNames ["kde" "kde-plasma" "plasma6"];

      catppuccin = {
        aliases = normalizeNames ["catppuccin-theme" "catpp"];
        flavors = normalizeNames ["latte" "frappe" "macchiato" "mocha"];
      };

      caelestia.aliases = normalizeNames ["caelestia-shell" "cls"];
      "dank-material-shell".aliases = normalizeNames ["dms" "dank"];
      "noctalia-shell".aliases = normalizeNames ["noctalia" "noctalia-dev"];
      nvf.aliases = normalizeNames ["nvim" "neovim"];

      "zen-browser" = {
        aliases = normalizeNames ["zen" "zen-twilight" "zen-beta" "zen-default"];
        variants = {
          twilight = normalizeNames ["zen" "zen-twilight" "zen twilight"];
          beta = normalizeNames ["zen-beta" "zen-default" "zen beta" "zen default"];
        };
      };
    };

    mappings = {
      command = {
        terminal = {
          foot = "feet";
          ghostty = "ghostty";
        };
        browser = {
          zen-twilight = "zen-twilight";
          zen-beta = "zen-beta";
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
        primary = "zen-twilight";
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
    variants = mapAttrs (_: values: normalizeNames values) (cfg.variants or {});
    isAllowed = condition ({inherit cfg name names flavors variants;} // context);
    module = mkModule {inherit inputs modules name variant;};
  in {inherit isAllowed module;};

  mkApps = {
    user,
    inputs,
    modules,
    ...
  }: let
    apps = user.applications or {};
    appsAllowed = normalizeNames (attrByPath ["applications" "allowed"] [] user);
    ui = user.interface or {};
    de = normalizeName (attrByPath ["desktopEnvironment"] "" ui);
    theme = let
      t = attrByPath ["style" "theme"] {} ui;
    in {
      light = normalizeName (t.light or "");
      dark = normalizeName (t.dark or "");
    };
    bar = normalizeName (attrByPath ["bar"] null apps);
    firefox = normalizeName (attrByPath ["browser" "firefox"] "" apps);
    tty = let
      t = attrByPath ["editor" "tty"] {} apps;
    in {
      primary = normalizeName (t.primary or "");
      secondary = normalizeName (t.secondary or "");
    };
    hasAnyApp = names: extras: isIn names (appsAllowed ++ normalizeNames extras);
    context = {inherit appsAllowed bar theme de firefox hasAnyApp tty;};

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
        || isIn flavors [theme.light theme.dark];

      caelestia.condition = {
        names,
        hasAnyApp,
        bar,
        ...
      }:
        hasAnyApp names [bar];
      "dank-material-shell".condition = {
        names,
        hasAnyApp,
        bar,
        ...
      }:
        hasAnyApp names [bar];
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
        hasAnyApp names [tty.primary tty.secondary];

      "zen-browser" = let
        cfg = defaults.apps."zen-browser";
        variant =
          if isIn (normalizeNames (cfg.variants.twilight or [])) firefox
          then "twilight"
          else "beta";
      in {
        inherit variant;
        condition = {
          names,
          hasAnyApp,
          firefox,
          ...
        }:
          hasAnyApp names [firefox];
      };
    };
  in
    mapAttrs (name: spec:
      mkApp (
        {inherit context name inputs modules;} // spec
      ))
    appSpecs;

  mkPrograms = {
    host,
    user,
  }: let
    inherit (defaults) mappings programs;
    hostApps = host.applications or {};
    userApps = user.applications or {};
    programDefaults = removeAttrs programs ["tui"];
    zenCfg = defaults.apps."zen-browser";
    zenNames = normalizeNames (["zen-browser"] ++ (zenCfg.aliases or []));

    rawTerm = normalizeName (
      attrByPath ["terminal" "primary"]
      (attrByPath ["terminal" "primary"] programs.terminal.primary hostApps)
      userApps
    );
    primaryTerminalCmd = attrByPath ["terminal" rawTerm] rawTerm mappings.command;

    getCommand = category: name: let
      n = normalizeName name;
      cmd =
        if category == "browser" && isIn zenNames n
        then
          attrByPath [
            "browser"
            (
              if isIn (zenCfg.variants.twilight or []) n
              then "zen-twilight"
              else "zen-beta"
            )
          ]
          n
          mappings.command
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
        attrByPath optionPath
        (attrByPath optionPath default hostCategory)
        userCategory
      );
      command = getCommand category name;
      class = getClass command;
    in {inherit command class;};

    mkCategory = category: options:
      mapAttrs (name: value: let
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
          default = cfg.default;
        })
      options;
  in
    mapAttrs mkCategory programDefaults // {inherit resolveProgram;};
in
  exports.internal // {_rootAliases = exports.external;}
