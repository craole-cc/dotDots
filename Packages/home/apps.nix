{
  pkgs,
  # config,
  # user,
  ...
}: {
  home.packages = with pkgs; [
    gImageReader
    inkscape
    # microsoft-edge
    qbittorrent-enhanced
    warp-terminal
    (pkgs.spacedrive.overrideAttrs (oldAttrs: {
      makeWrapperArgs = [
        "--set GDK_BACKEND x11"
        "--add-flags '--disable-gpu'"
        "--add-flags '--disable-gpu-compositing'"
      ];
    }))

    swaybg
    cachix
    lsd
    eza
  ];

  # stylix.targets = {
  #   zen-browser = {
  #     enable = true;
  #     profileNames = ["default"];
  #   };
  # };

  programs = {
    clock-rs.enable = true;
    # alacritty.enable = true; # Super+T in the default setting (terminal)
    # fuzzel.enable = true; # Super+D in the default setting (app launcher)
    # swaylock.enable = true; # Super+Alt+L in the default setting (screen locker)
    # waybar.enable = true; # launch on startup in the default setting (bar)
  };
  services = {
    mako.enable = true; #
    # polkit-gnome.enable = true; # polkit
  };
}
