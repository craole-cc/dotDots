{
  settings = {
    #| Daemon mode:
    # -- Single instance across all windows (reduced memory footprint)
    # -- Stays running when all windows are closed (instant reopening)
    # -- No initial window (spawn via keybind when needed)
    gtk-single-instance = true;
    quit-after-last-window-closed = false;
    # initial-window = false;
    right-click-action = "copy-or-paste";
    selection-clear-on-copy = true;
    mouse-hide-while-typing = true;

    confirm-close-surface = false;

    background-blur = true;
    font-size = 14;
    # keybind = [
    #   "clear"
    #   "ctrl+h=goto_split:left"
    #   "ctrl+l=goto_split:right"
    # ];

    #~@ Enable systemd integration for automatic startup
    # theme = "light:Catppuccin Latte,dark:Catppuccin Frappe";
    # theme = "light:Rose Pine Dawn,dark:Rose Moon";
  };
}
