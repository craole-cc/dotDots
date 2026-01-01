{
  lib,
  lix,
  user,
  config,
  nixosConfig,
  pkgs,
  src,
  ...
}: let
  app = "plasma";
  opt = [app "kde" "plasma6"];

  inherit (lib.modules) mkIf;
  inherit (lix.lists.predicates) isIn;
  isAllowed = isIn (user.interface.desktopEnvironment or null) opt;
  isAvailable = config?programs.${app};
in {
  config = mkIf (isAllowed && isAvailable) {
    programs = {
      ${app} =
        {enable = true;}
        // import ./bindings
        # // import ./files
        // import ./modules {inherit src pkgs config nixosConfig;};
    };

    home = {
      shellAliases = {
        plasma-config-dump = "nix run github:nix-community/plasma-manager > $DOTS/Packages/home/interface/plasma/dump.nix";
      };
      packages = with pkgs;
        [
          #~@ KDE Themes
          plasma-overdose-kde-theme
          materia-kde-theme
          arc-kde-theme
          twilight-kde
          adapta-kde-theme
          sweet-nova
          utterly-nord-plasma
          utterly-round-plasma-style
          catppuccin-kde

          #~@ SDDM Themes
          catppuccin-sddm-corners

          #~@ Kvantum Themes
          catppuccin-kvantum
          gruvbox-kvantum
          rose-pine-kvantum
          ayu-theme-gtk
          kvmarwaita
          rose-pine-kvantum

          #~@ GTK Themes
          rose-pine-gtk-theme
          jasper-gtk-theme
          fluent-gtk-theme
          colloid-gtk-theme
          juno-theme
          yaru-remix-theme
          catppuccin-gtk
          lavanda-gtk-theme
          kanagawa-gtk-theme
          magnetic-catppuccin-gtk
          rose-pine-gtk-theme

          #~@ Cursors
          catppuccin-cursors
          rose-pine-cursor

          #~@ Icons
          candy-icons
          rose-pine-icon-theme

          #~@ Visuals
          kurve
          catppuccin
        ]
        ++ (with kdePackages; [
          koi
          krohnkite
          yakuake
        ]);
    };
  };
}
