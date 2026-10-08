let
  enable = true;
  flavor = "frappe";
  accent = "teal";
in {
  catppuccin = {
    inherit accent enable flavor;
    autoEnable = enable;

    cache = {inherit enable;};
    cursors = {inherit accent enable flavor;};
    enableReleaseCheck = enable;
    fcitx5 = {
      inherit accent enable flavor;
      enableRounded = enable;
    };
    fish = {
      enable = true;
    };
    forgejo = {inherit accent enable flavor;};
    gitea = {inherit accent enable flavor;};
    grub = {inherit enable flavor;};
    gtk.icon = {inherit accent enable flavor;};
    home-assistant = {
      inherit accent enable flavor;
      setDefaultAtStartup = true;
    };
    limine = {inherit accent enable flavor;};
    plymouth = {inherit enable flavor;};
    sddm = {
      inherit accent;
      assertQt6Sddm = true;
      background = "backgrounds/wall.png";
      clockEnabled = true;
      inherit enable;
      inherit flavor;
      font = "Noto Sans";
      fontSize = "9";
      loginBackground = true;
      userIcon = true;
    };
    tty = {inherit enable flavor;};
  };
}
