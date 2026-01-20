{
  config,
  host,
  lib,
  user,
  ...
}: let
  inherit (lib.attrsets) attrByPath;
  inherit (lib.strings) hasPrefix removePrefix removeSuffix;
  inherit (lib.lists) toList;

  mkDefault = {
    default,
    home ? config.home.homeDirectory,
    dots ? host.paths.dots,
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

  wallpapers = rec {
    all = mkDefault {
      path = ["wallpapers" "all"];
      default = "home:Pictures/Wallpapers";
    };
    dark = mkDefault {
      path = ["wallpapers" "dark"];
      default = all + "/dark.jpg";
    };
    light = mkDefault {
      path = ["wallpapers" "light"];
      default = all + "/light.jpg";
    };
    "eDP-1" = mkDefault {
      path = ["wallpapers" "all" "eDP-1"];
      default = all + "/16x9";
    };
  };
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
in {
  _module.args.paths = {
    inherit avatars mkDefault wallpapers;
  };
}
