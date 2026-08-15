{
  lib ? null,
  flake ? null,
  paths ? {
    src = ./.;
    libraries = ./Libraries/nix;
  },
  names ? {
    src = "dots";
    top = "_";
    lib = "lix";
    alpha = "craole"; # TODO: This should be host driven. The primary user;
  },
  cfg ? {
    name = "dotDots";
    version = "2.0.0";
    cache = ".cache";
    prefix = ".";
  },
  topOverride ? null,
}: let
  libraries = import paths.libraries {
    inherit
      paths
      flake
      names
      lib
      ;
  };
  inherit (libraries) lix;
  inherit (lix.attrsets.construction) mkEnvVars;
  inherit (lix.filesystem.tree) mkTree mkLangGroup;
  inherit (lix.schema._) mkSchema;
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
  # `top` is resolved from the most authoritative source available: an
  # explicit function argument (the CLI/embedding override), then DOTS_TOP,
  # then the persisted API global names record, and finally root `names.top`.
  global =
    if tree.store.api.global != null
    then import tree.store.api.global
    else {};
  src = global.names.src or (names.src or "dots");
  user = global.names.alpha or (names.alpha or "craole");
  home = "/home/${user}";
  top = let
    key = lix.strings.transformation.toUpper "${src}_TOP";
    env = builtins.getEnv key;
  in
    if topOverride != null
    then topOverride
    else if env != "" && env != null
    then env
    else global.names.top or (names.top or "_");

  env = mkEnvVars {
    type = "set";
    uppercase = true;
    vars = [
      # -- System & User Basics --
      {
        name = "USER";
        value = user;
      }
      {
        name = "HOME";
        value = home;
      }
      {
        name = "SHELL";
        value = "/bin/bash";
      }

      # -- XDG Base Directory Specification --
      {
        name = "XDG_CONFIG_HOME";
        value = "${home}/.config";
      }
      {
        name = "XDG_DATA_HOME";
        value = "${home}/.local/share";
      }
      {
        name = "XDG_CACHE_HOME";
        value = "${home}/.cache";
      }
      {
        name = "XDG_STATE_HOME";
        value = "${home}/.local/state";
      }
      {
        name = "XDG_BIN_HOME";
        value = "${home}/.local/bin";
      }
      {
        name = "XDG_RUNTIME_DIR";
        value = "/run/user/1000";
      }

      # -- Networking / Host Defaults --
      {
        name = "HOSTNAME";
        value = "localhost";
      }
      {
        name = "HOST";
        value = "127.0.0.1";
      }
      {
        name = "PORT";
        value = "8080";
      }

      # -- Dotfiles & Custom Top Targets --
      {
        name = "${src}_top";
        value = top;
      }
      {
        name = "${src}_config";
        value = "${home}/.config/${src}";
      }

      # -- Standard Interactive Utilities --
      {
        name = "EDITOR";
        value = "nvim";
      }
      {
        name = "VISUAL";
        value = "nvim";
      }
      {
        name = "PAGER";
        value = "less";
      }
      {
        name = "BROWSER";
        value = "firefox";
      }
      {
        name = "TERMINAL";
        value = "alacritty";
      }

      # -- Development & Build Context --
      {
        name = "TMPDIR";
        value = "/tmp";
      }
      {
        name = "LANG";
        value = "en_US.UTF-8";
      }
      {
        name = "TZ";
        value = "UTC";
      }
    ];
  };
  schema = mkSchema {inherit tree;};
  inherit (schema) hosts users;
in {
  inherit
    cfg
    env
    global
    hosts
    lix
    paths
    schema
    top
    tree
    users
    ;
}
