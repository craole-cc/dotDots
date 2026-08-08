{config, top, ...}: {
  programs.home-manager = {
    enable = config.${top}.applications.utilities.home-manager.enable;
    # autoExpire.enable = true;
  };
  news.display = "silent";
  manual.html.enable = true;
}
