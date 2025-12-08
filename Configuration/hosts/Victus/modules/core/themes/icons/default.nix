{
  lix,
  pkgs,
  ...
}: let
  inherit (lix.sources) iconOf;

  nixos = let
    pack = "nixos-icons";
    path = "share/icons/hicolor/scalable/apps";
  in {
    snowflake = iconOf {
      inherit pkgs pack path;
      name = "nix-snowflake.svg";
    };
  };
in {
  _module.args.icons = {inherit nixos;};
}
