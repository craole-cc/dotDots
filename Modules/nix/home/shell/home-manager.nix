{config, top, ...}: {
  programs.home-manager = {
    enable = config.${top}.inputs.applications.utilities.home-manager.enable;
    # autoExpire.enable = true;
  };
  news.display = "silent";
  manual.html.enable = true;
  ${top}.output = {
    programs.home-manager = config.programs.home-manager;
    news.display = "silent";
    manual.html.enable = true;
  };
}
