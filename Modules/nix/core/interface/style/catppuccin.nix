let
  enable = true;
  flavor = "latte";
  accent = "teal";
in {
  catppuccin = {
    # Preserve the current explicit-port behaviour while opting into the new
    # global-toggle semantics expected by catppuccin/nix.
    accent = "teal";
    autoEnable = enable;
    cache = {
      inherit enable;
    };
    cursors = {
      inherit accent enable flavor;
    };
    inherit enable;
    enableReleaseCheck = true;
    fcitx5 = {
      inherit accent;
      inherit enable;
      enableRounded = true;
      inherit flavor;
    };
    fish = {
      inherit enable flavor;
    };
    inherit flavor;
    forgejo = {
      inherit accent enable flavor;
    };
    gitea = {
      inherit accent enable flavor;
    };
    grub = {
      inherit enable flavor;
    };
    gtk = {
      icon = {
        inherit accent enable flavor;
      };
    };
    home-assistant = {
      inherit accent enable flavor;
      setDefaultAtStartup = true;
    };
    limine = {
      inherit accent enable flavor;
    };
    plymouth = {
      inherit enable flavor;
    };
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
    tty = {
      inherit enable flavor;
    };
  };
}
