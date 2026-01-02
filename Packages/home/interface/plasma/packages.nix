{pkgs, ...}: let
  toggleTerminal = pkgs.stdenv.mkDerivation rec {
    pname = "kwin-toggleterminal";
    version = "unstable-2024";
    src = pkgs.fetchFromGitHub {
      owner = "DvdGiessen";
      repo = pname;
      rev = "main";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==="; # Run: nix-prefetch-github --owner DvdGiessen --repo kwin-toggleterminal --rev main
    };
    installPhase = ''
      mkdir -p $out/share/kwin/scripts/${pname}
      cp -r . $out/share/kwin/scripts/${pname}
    '';
  };
in
  with pkgs;
    [
      toggleTerminal

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
      kpackage
      krohnkite
      yakuake
    ])
