{
  host,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (host.interface.desktopEnvironment == "gnome") {
    programs =
      {}
      // import ./extension.nix {inherit pkgs;}
      // import ./terminal.nix
      // {};
    services =
      {}
      // import ./keyring.nix
      // import ./polkit.nix
      // {};
  };
}
