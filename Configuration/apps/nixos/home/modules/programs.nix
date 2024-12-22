{ specialArgs, lib, ... }:
let
  inherit (specialArgs) users;
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.lists) any;
in
{
  programs.hyprland.enable = any (user: user.desktop.manager or null == "hyprland") (users);
}
