{lib, ...}: let
  inherit
    (lib.strings)
    concatStringsSep
    hasPrefix
    isList
    removePrefix
    removeSuffix
    splitString
    concatMapStringsSep
    toList
    ;
  inherit (lib.asserts) assertMsg;
  inherit (lib.attrsets) attrByPath mapAttrs mapAttrsToList;
  inherit (lib.list) elemAt head;
  /**
  Constructs a file path by combining a root directory with a stem (file name or relative path).

  The function validates that both `root` and `stem` are non-empty strings before construction.
  The `stem` can be either a string or a list of strings; if a list is provided, the elements
  are joined with forward slashes.

  Arguments:
    - root (string): The root directory path. Must not be null or empty.
    - stem (string|list): The file name or relative path. Must not be null or empty.
    If a list, elements are concatenated with "/".

  Returns:
    string: The fully constructed path in the format "root/stem".

  Throws:
    Assertion error if `root` or `stem` is null or empty.

  Example:
    construct { root = "/home/user"; stem = "documents/file.txt"; }
    => "/home/user/documents/file.txt"

    construct { root = "/var"; stem = ["log" "app" "output.log"]; }
    => "/var/log/app/output.log"
  */
  construct = {
    root,
    stem,
  }:
    assert assertMsg (
      root != null && root != ""
    ) "root must not be empty";
    assert assertMsg (
      stem != null && stem != "" && stem != []
    ) "stem must not be empty"; "${root}/${
      if isList stem
      then concatStringsSep "/" stem
      else stem
    }";

  getDefaults = {
    config,
    host,
    user,
    pkgs,
    paths ? {},
    ...
  }: let
    inherit
      (pkgs)
      coreutils
      fd
      imagemagick
      replaceVarsWith
      ripgrep
      writeShellScriptBin
      ;
    inherit (host.paths) dots;
    home = config.home.homeDirectory or builtins.getEnv "HOME";

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
          manager = replaceVarsWith {
            src = ./wallman.sh;
            name = "wallman-${name}";
            replacements = {
              inherit name resolution directory current;
              cmdConvert = "${imagemagick}/bin/convert";
              cmdFd = "${fd}/bin/fd";
              cmdRg = "${ripgrep}/bin/rg";
              cmdLn = "${coreutils}/bin/ln";
              cmdShuf = "${coreutils}/bin/shuf";
              cmdRealpath = "${coreutils}/bin/realpath";
              cachePolarity = "${cache}/polarity.txt";
              cachePurity = "${cache}/purity.txt";
              cacheCategory = "${cache}/category.txt";
              cacheFavorite = "${cache}/favorite.txt";
            };
            isExecutable = true;
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

      #> Global wallpaper manager
      manager = writeShellScriptBin "wallman" ''
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
    exports = {inherit api avatars dots home wallpapers;};
  in
    paths // exports;

  mkDefault = {
    default,
    root ? "home",
    path ? [],
    dots,
    home,
    user,
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
    path' = toList path;
    relative =
      if path' != []
      then attrByPath path' default user.paths
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
in {
  inherit construct mkDefault getDefaults;
  _rootAliases = {
    buildPath = construct;
    getDefaultPaths = getDefaults;
    mkDefaultPath = mkDefault;
  };
}
