{
  lib,
  lix,
  user,
  host,
  config,
  ...
}: let
  inherit (lib.attrsets) attrByPath;
  inherit
    (lib.strings)
    concatStringsSep
    hasInfix
    hasPrefix
    optionalString
    removePrefix
    removeSuffix
    toUpper
    ;
  inherit (lib.lists) head toList;

  apps = let
    mkDefault = {
      category,
      option,
      default,
    }: let
      name =
        user.applications.${category}.${option} or
        host.applications.${category}.${option} or
        default;

      command =
        if category == "terminal"
        then
          if name == "foot"
          then "feet"
          else name
        else if category == "browser"
        then
          if hasInfix "zen" name
          then
            if hasInfix "twilight" name
            then "zen-twilight"
            else "zen-beta"
          else if hasInfix "edge" name
          then "microsoft-edge"
          else name
        else if category == "editor"
        then
          if hasInfix "code" name
          then "code"
          else if hasInfix "zed" name
          then "zeditor"
          else name
        else if category == "launcher"
        then
          if name == "vicinae"
          then "vicinae toggle"
          else if name == "fuzzel"
          then "pkill fuzzel || fuzzel --list-executables-in-path"
          else name
        else name;

      class =
        if command == "feet"
        then "foot"
        else if command == "ghostty"
        then "com.mitchellh.ghostty"
        else if command == "zeditor"
        then "dev.zed.Zed"
        else if (hasInfix "fuzzel" command)
        then "fuzzel"
        else if (hasInfix "vicinae" command)
        then "vicinae"
        else command;
    in {inherit command class;};
    browser = {
      primary = mkDefault {
        category = "browser";
        option = "primary";
        default = "zen-twilight";
      };
      secondary = mkDefault {
        category = "browser";
        option = "secondary";
        default = "microsoft-edge";
      };
    };
    editor = {
      primary = mkDefault {
        category = "editor";
        option = "gui.primary";
        default = "vscode";
      };
      secondary = mkDefault {
        category = "editor";
        option = "gui.secondary";
        default = "zed";
      };
    };
    launcher = {
      primary = mkDefault {
        category = "launcher";
        option = "primary";
        default = "vicinae";
      };
      secondary = mkDefault {
        category = "launcher";
        option = "secondary";
        default = "fuzzel";
      };
    };
    terminal = {
      primary = mkDefault {
        category = "terminal";
        option = "primary";
        default = "foot";
      };
      secondary = mkDefault {
        category = "terminal";
        option = "secondary";
        default = "ghostty";
      };
    };
  in {inherit mkDefault browser editor launcher terminal;};

  keyboard = let
    fromUser = user.interface.keyboard or {};
    fromHost = host.interface.keyboard or {};
  in {
    mod = toUpper (
      fromUser.modifier or
      fromHost.modifier or
      "Super"
    );
    swapCapsEscape =
      fromUser.swapCapsEscape or
      fromHost.swapCapsEscape or
      null;
    vimKeybinds =
      fromUser.vimKeybinds or
      fromHost.vimKeybinds or
      false;
  };

  city = host.localization.city or "Mandeville, Jamaica";
  fonts =
    user.interface.style.fonts or
    host.interface.style.fonts or {
      emoji = "Noto Color Emoji";
      monospace = "Maple Mono NF";
      sans = "Monaspace Radon Frozen";
      serif = "Noto Serif";
      material = "Material Symbols Sharp";
      clock = "Rubik";
    };

  paths = let
    mkDefault = {
      home ? config.home.homeDirectory,
      dots ? host.paths.dots,
      default ? "",
      path ? "",
      stem ? [],
    }: let
      #> Ensure stem is a list of strings
      stems = toList stem;

      #> Get the value from user.paths following the stem path
      relative =
        if stems != [] && user.paths ? ${concatStringsSep "." stems}
        then user.paths.${concatStringsSep "." stems}
        else if stems != [] && user.paths ? ${head stems}
        then attrByPath stems default user.paths
        else default;

      absolute =
        if path != ""
        then removeSuffix "/" path
        else home;

      final =
        if (hasPrefix "/" relative) || (hasPrefix "root:" relative)
        then relative
        else if hasPrefix "dots:" relative
        then dots + "/" + (removePrefix "dots:" relative)
        else absolute + "/" + (removePrefix "home:" relative);
    in
      optionalString (relative == "") final;

    wallpapers = with wallpapers; {
      all = mkDefault {
        stem = "wallpapers";
        default = "${dots}/Assets/Images/wallpapers";
      };
      "eDP-1" = all + "/16x9/Landscape/earth.jpg";
    };
    avatars = {
      session = mkDefault {
        stem = ["avatars" "session"];
        default = "root:/assets/kurukuru.gif";
      };
      media = mkDefault {
        stem = ["avatars" "media"];
        default = "root:/assets/kurukuru.gif";
      };
    };
  in {inherit mkDefault wallpapers avatars;};
in {
  _module.args = {
    inherit
      apps
      city
      fonts
      keyboard
      paths
      ;
  };
  imports = lix.filesystem.importers.importAll ./.;
}
