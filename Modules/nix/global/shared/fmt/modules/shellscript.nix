{
  programs = {
    shellcheck.enable = true;

    shfmt = {
      enable = true;
      indent_size = 2;
      simplify = true;
    };
  };

  settings.formatter = {
    shellcheck = {
      priority = 1;
      options = ["--rcfile" ".shellcheckrc"];
    };

    shfmt = {
      priority = 2;
      options = [
        "--apply-ignore"
        "--binary-next-line"
        "--space-redirects"
        "--case-indent"
      ];
    };
  };
}
