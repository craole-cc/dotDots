{pkgs, ...}: {
  services = {
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    desktopManager.plasma6.enable = true;
  };

  environment = {
    systemPackages = with pkgs;
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

        #~@ Visuals
        kurve
      ]
      ++ (with kdePackages; [
        #~@ Themes
        koi

        #~@ Window Management
        krohnkite

        #~@ Applications
        plasmatube
        calindori
        karp

        #~@ Utilities
        kup
        qxlsx
      ]);
    plasma6.excludePackages = with pkgs.kdePackages; [
      # konsole
      kate
    ];
  };
}
