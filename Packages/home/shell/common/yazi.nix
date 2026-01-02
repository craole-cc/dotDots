{
  pkgs,
  lib,
  ...
}: let
  inherit (lib.lists) optionals;
in {
  programs.yazi = {
    enable = true;
  };

  home = {
    packages = with pkgs.yaziPlugins;
      [
        bookmarks
        bypass
        chmod
        compress
        diff
        duckdb
        dupes
        full-border
        gitui
        glow
        lazygit
        lazygit
        lsar
        mediainfo
        miller
        mime-ext
        mount
        no-status
        nord
        ouch
        piper
        projects
        recycle-bin
        relative-motions
        restore
        rich-preview
        rsync
        smart-enter
        smart-filter
        smart-paste
        starship
        sudo
        time-travel
        toggle-pane
        vcs-files
        wl-clipboard
        yatline-catppuccin
        yatline-githead
      ]
      ++ optionals (pkgs.stdenv.isDarwin) [mactag];
  };
}
