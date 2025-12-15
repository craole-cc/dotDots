{
  programs.foot.settings = {
    main = {
      font = "monospace:size=14";
      dpi-aware = "yes";
      pad = "8x8"; # Padding around terminal content
    };

    mouse = {
      hide-when-typing = "yes";
    };

    scrollback = {
      lines = 10000;
    };

    # url = {
    #   launch = "xdg-open \${url}"; #? Click URLs to open in browser
    #   protocols = "http, https, ftp, ftps, file";
    # };
  };
}
