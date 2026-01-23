{
  config,
  host,
  lib,
  user,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrByPath mapAttrs;
  inherit (lib.strings) hasPrefix removePrefix removeSuffix splitString concatMapStringsSep;
  inherit (lib.lists) elemAt isList toList head mapAttrsToList;
  inherit (host.paths) dots;
  inherit
    (pkgs)
    coreutils
    findutils
    imagemagick
    substituteAll
    writeShellScript
    ;
  home = config.home.homeDirectory;

  mkDefault = {
    default,
    root ? "home",
    path ? [],
  }: let
    #> Resolve the base directory
    absolute =
      if root == "dots"
      then dots
      else if root == "home"
      then home
      else if root != ""
      then removeSuffix "/" root
      else home; #? fallback to home if empty string

    #> Get the value from user.paths
    attrPath = toList path;
    relative =
      if attrPath != []
      then attrByPath attrPath default user.paths
      else default;
  in
    if (hasPrefix "/" relative) || (hasPrefix "root:" relative)
    then
      #? Already absolute path
      # Example: "/foo/bar" || "root:/foo/bar"
      # -> "/foo/bar" || "root:/foo/bar"
      relative
    else if (hasPrefix "dots:" relative) || (hasPrefix "$DOTS/" relative)
    then
      #? Path relative to dots directory (configuration repository)
      # Example: "dots:Assets/Images" || "$DOTS/Assets/Images"
      # -> "/path/to/dotfiles/Assets/Images"
      dots + "/" + (removePrefix "dots:" (removePrefix "$DOTS/" relative))
    else if (hasPrefix "home:" relative) || (hasPrefix "$HOME/" relative)
    then
      #? Path relative to home directory
      # Example: "home:Pictures" || "$HOME/Pictures"
      # -> "/home/${username}/Pictures"
      absolute + "/" + (removePrefix "home:" (removePrefix "$HOME/" relative))
    else
      #? Fallback:Path relative to the base directory
      # Example: "wallpapers/dark.jpg"
      # -> "/base/dir/wallpapers/dark.jpg"
      absolute + "/" + relative;

  wallpapers = let
    raw = attrByPath ["wallpapers" "all"] null user.paths;
    all =
      if isList raw
      then map (p: mkDefault {default = p;}) raw
      else [
        (mkDefault {
          path = ["wallpapers" "all"];
          default = "home:Pictures/Wallpapers";
        })
      ];

    primary = mkDefault {
      path = ["wallpapers" "primary"];
      default = head all;
    };

    dark = mkDefault {
      path = ["wallpapers" "dark"];
      default = primary + "/dark.jpg";
    };

    light = mkDefault {
      path = ["wallpapers" "light"];
      default = primary + "/light.jpg";
    };

    monitors =
      mapAttrs (name: config: let
        transformation = config.transform or 0;
        rotation =
          if transformation == 1
          then 90
          else if transformation == 2
          then 180
          else if transformation == 3
          then 270
          else 0;

        isRotated = rotation == 90 || rotation == 270;
        isFlipped = rotation == 180;

        resolution =
          if isRotated
          then let
            parts = splitString "x" config.resolution;
            width = elemAt parts 0;
            height = elemAt parts 1;
          in "${height}x${width}"
          else config.resolution;

        directory = mkDefault {
          path = ["wallpapers" "monitors" name "directory"];
          default = primary + "/${resolution}";
        };
        dark = mkDefault {
          path = ["wallpapers" "monitors" name "dark"];
          default = directory;
        };

        light = mkDefault {
          path = ["wallpapers" "monitors" name "light"];
          default = directory;
        };
        cache = directory + "/.cache";
        current = primary + "/current-${name}.jpg";

        manager = substituteAll {
          src = ./wallman.sh;
          inherit name resolution directory current cache;
          convert = "${imagemagick}/bin/convert";
          find = "${findutils}/bin/find";
          ln = "${coreutils}/bin/ln";
          shuf = "${coreutils}/bin/shuf";
        };
      in {
        inherit
          directory
          current
          cache
          isFlipped
          isRotated
          name
          resolution
          rotation
          transformation
          manager
          dark
          light
          ;
      })
      host.devices.display;

    #> Global wallpaper manager (simple wrapper calling individual managers)
    manager = writeShellScript "wallman" ''
      #!/bin/sh
      set -eu

      if [ $# -lt 1 ]; then
        printf "Usage: %s <command> [options]\n" "$0" >&2
        exit 1
      fi

      ${
        concatMapStringsSep "\n"
        (mgr: ''${mgr} "$@" || true'')
        (mapAttrsToList (name: config: config.manager) monitors)
      }
    '';
  in {inherit all primary dark light monitors manager;};

  avatars = {
    session = mkDefault {
      path = ["avatars" "session"];
      default = "root:/assets/kurukuru.gif";
    };
    media = mkDefault {
      path = ["avatars" "media"];
      default = "root:/assets/kurukuru.gif";
    };
  };

  api = {
    host = mkDefault {
      default = "dots:API/hosts/${host.name}/default.nix";
    };
    user = mkDefault {
      default = "dots:API/users/${user.name}/default.nix";
    };
  };
in {
  _module.args.paths = {
    inherit avatars mkDefault wallpapers dots api;
  };
}
