{
  host,
  lib,
  pkgs,
  user,
  ...
}: let
  inherit (lib.strings) hasInfix;

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

  explorer = {
    primary = mkDefault {
      category = "explorer";
      option = "primary";
      default = "yazi";
    };
    secondary = mkDefault {
      category = "explorer";
      option = "secondary";
      default = "org.gnome.Nautilus";
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
in {
  _module.args.apps = {
    inherit
      mkDefault
      browser
      editor
      explorer
      launcher
      terminal
      ;
  };

  home.packages = with pkgs; [
    gImageReader
    # inkscape
    qbittorrent-enhanced
    # warp-terminal
    # (spacedrive.overrideAttrs (oldAttrs: {
    #   makeWrapperArgs = [
    #     "--set GDK_BACKEND x11"
    #     "--add-flags '--disable-gpu'"
    #     "--add-flags '--disable-gpu-compositing'"
    #   ];
    # }))

    swaybg
  ];
}
