{
  lib ? {},
  flake ? null,
  root ? null,
}: let
  inherit
    (builtins)
    concatStringsSep
    filter
    isAttrs
    isList
    mapAttrs
    pathExists
    ;

  /**
  Safely reads an environment variable, returning a fallback default if unset or empty.

  # Arguments
  `env` (string)
  : The name of the environment variable to query.

  `default` (any)
  : The fallback value to return if the environment variable is empty or unset.
  */
  getEnv = env: default: let
    resolved = builtins.getEnv env;
  in
    if resolved != ""
    then resolved
    else default;

  /**
  Safely imports a file at the given path if it exists on disk; otherwise returns an empty set.

  # Arguments
  `path` (path or string)
  : The filesystem path to check and conditionally import.
  */
  importAttr = path:
    if pathExists path
    then import path
    else {};

  /**
  Recursively merges two attribute sets (right-hand set2 overrides left-hand set1).

  # Arguments
  `set1` (attrset)
  : The base attribute set.

  `set2` (attrset)
  : The overriding attribute set whose values take precedence.
  */
  mergeAttr = set1: set2: let
    fn = attrPath: lhs: rhs:
      if isAttrs lhs && isAttrs rhs
      then mapAttrs (key: val: fn (attrPath ++ [key]) val (rhs.${key} or lhs.${key})) lhs // rhs
      else rhs;
  in
    if isAttrs set1 && isAttrs set2
    then fn [] set1 set2
    else if isAttrs set2
    then set2
    else set1;

  /**
  Recursively maps relative path stem strings into `{ store, local }` location records.

  # Arguments
  `base` (attrset)
  : An attribute set containing `{ store, local }` root paths.

  `stem` (attrset or string)
  : A path stem string or nested attribute set of stem strings to map.
  */
  mkPathAttr = base: stem:
    if isAttrs stem
    then mapAttrs (_: part: mkPathAttr base part) stem
    else if isList stem
    then let
      relPath = concatStringsSep "/" stem;
    in {
      store = base.store + "/${relPath}";
      local = concatStringsSep "/" (filter (x: x != "") [base.local relPath]);
    }
    else stem;

  cfg = let
    global = import ./API/nix/global;
    host = let
      name = getEnv "HOSTNAME" "Victus";
      path = ./. + "/${global.paths.api.hosts}/${name}";
    in
      importAttr path;
  in
    mergeAttr global host;

  inherit (cfg) names;

  paths = let
    src = {
      store = ./.;
      local =
        if root != null
        then root
        else getEnv "PWD" cfg.paths.src;
    };
  in
    mkPathAttr src cfg.paths // {inherit src;};

  libraries = import paths.lib.default.store {
    inherit names paths flake;
    lib =
      lib
      // {inherit getEnv importAttr mergeAttr mkPathAttr;};
  };
  _ = libraries.${names.lib};
  inherit (_.attrsets.construction) mkEnvVars;
  inherit (_.filesystem.tree) mkTree mkLangGroup;
  inherit (_.schema._) mkSchema;

  tree = mkTree {
    stems = {
      api = let
        base = [
          "API"
          "nix"
        ];
      in
        mkLangGroup ["API"] {
          nix = "nix";
          rs = "rust";
        }
        // {
          global = base ++ ["global"];
          hosts = base ++ ["hosts"];
          users = base ++ ["users"];
        };

      cfg = {
        default = ["Configuration"];
      };

      env = {
        default = ["Environment"];
      };

      kit = let
        base = [
          "Templates"
          "nix"
        ];
      in
        mkLangGroup ["Templates"] {
          nix = "nix";
          rs = "rust";
          sh = "shellscript";
        }
        // {
          common = base ++ ["common"];
          dev = base ++ ["dev"];
          media = base ++ ["media"];
          full = base ++ ["full"];
        };

      lib = mkLangGroup ["Libraries"] {
        bash = "bash";
        nix = "nix";
        nu = "nushell";
        sh = "shellscript";
        pwsh = "powershell";
        py = "python";
        rs = "rust";
      };

      mod = let
        base = [
          "Modules"
          "nix"
        ];
      in
        mkLangGroup ["Modules"] {
          nix = "nix";
          rs = "rust";
        }
        // {
          global = base ++ ["global"];
          core = base ++ ["core"];
          home = base ++ ["home"];
        };

      pkg = let
        base = [
          "Packages"
          "nix"
        ];
      in
        mkLangGroup ["Packages"] {
          nix = "nix";
          rs = "rust";
        }
        // {
          global = base ++ ["global"];
          core = base ++ ["core"];
          home = base ++ ["home"];
          overlays = base ++ ["overlays"];
          plugins = base ++ ["plugins"];
        };

      sec = let
        base = ["Private"];
      in {
        default = base;
        age = base ++ ["secrets.nix"];
        vpn = base ++ ["vpn.age"];
      };

      res = let
        images = [
          "Assets"
          "Images"
        ];
      in {
        default = ["Assets"];
        inherit images;
        fonts = [
          "Assets"
          "Fonts"
        ];
        icons = [
          "Assets"
          "Icons"
        ];
        ascii = images ++ ["ascii"];
        logo = images ++ ["logo"];
        wallpapers = images ++ ["wallpaper"];
      };
    };
  };

  env = let
  in
    mkEnvVars {
      type = "set";
      uppercase = true;
      vars = [
        # -- System & User Basics --
        {
          name = "USER";
          default = user;
        }
        {
          name = "HOME";
          default = home;
        }
        {
          name = "SHELL";
          default = "/bin/bash";
        }

        # -- XDG Base Directory Specification --
        {
          name = "XDG_CONFIG_HOME";
          default = "${home}/.config";
        }
        {
          name = "XDG_DATA_HOME";
          default = "${home}/.local/share";
        }
        {
          name = "XDG_CACHE_HOME";
          default = "${home}/.cache";
        }
        {
          name = "XDG_STATE_HOME";
          default = "${home}/.local/state";
        }
        {
          name = "XDG_BIN_HOME";
          default = "${home}/.local/bin";
        }
        {
          name = "XDG_RUNTIME_DIR";
          default = "/run/user/1000";
        }

        # -- Networking / Host Defaults --
        {
          name = "HOSTNAME";
          default = "localhost";
        }
        {
          name = "HOST";
          default = "127.0.0.1";
        }
        {
          name = "PORT";
          default = "8080";
        }

        # -- Dotfiles, Custom Top Targets & Directories --
        {
          name = "${src}_HOME";
          default = src;
        }
        {
          name = "${src}_TOP";
          default = top;
        }
        {
          name = "${src}_CFG";
          default = "${top}/Configuration";
        }
        # {
        #   name = "${src}_LIB";
        #   default = dotsLib;
        # }
        # {
        #   name = "${src}_lib_bash";
        #   default = "${dotsLib}/bash";
        # }
        # {
        #   name = "${src}_lib_cmd";
        #   default = "${dotsLib}/cmd";
        # }
        # {
        #   name = "${src}_lib_nix";
        #   default = "${dotsLib}/nix";
        # }
        # {
        #   name = "${src}_lib_nu";
        #   default = "${dotsLib}/nushell";
        # }
        # {
        #   name = "${src}_lib_ps";
        #   default = "${dotsLib}/powershell";
        # }
        # {
        #   name = "${src}_lib_py";
        #   default = "${dotsLib}/python";
        # }
        # {
        #   name = "${src}_lib_rs";
        #   default = "${dotsLib}/rust";
        # }
        # {
        #   name = "${src}_lib_sh";
        #   default = dotsLibSh;
        # }
        # {
        #   name = "${src}_lib_xml";
        #   default = "${dotsLib}/xml";
        # }

        # -- Binit & Tooling Initialization --
        # {
        #   name = "BINIT_PATH";
        #   default = "${dotsLibSh}/base/binit";
        # }
        {
          name = "BINIT_ACTION";
          default = "--run";
        }
        {
          name = "NIXPKGS_ALLOW_UNFREE";
          default = "1";
        }
        # -- Standard Interactive Utilities --
        {
          name = "EDITOR";
          default = "hx";
        }
        {
          name = "VISUAL";
          default = "code";
        }
        {
          name = "PAGER";
          default = "less";
        }
        {
          name = "BROWSER";
          default = "firefox";
        }
        {
          name = "TERMINAL";
          default = "ghostty";
        }

        # -- Development & Build Context --
        {
          name = "TMPDIR";
          default = "/tmp";
        }
        {
          name = "LANG";
          default = "en_US.UTF-8";
        }
        {
          name = "TZ";
          default = "UTC";
        }
      ];
    };
  schema = mkSchema {inherit tree;};
  inherit (schema) hosts users;
in {
  inherit
    cfg
    env
    hosts
    paths
    schema
    tree
    users
    ;
  inherit (names) top;
  "${names.lib}" = _;
}
