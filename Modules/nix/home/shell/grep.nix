{config, top, ...}: {
  programs = {
    ripgrep = {
      enable = config.${top}.inputs.applications.utilities.grep.enable;
      arguments = [
        "--max-columns-preview"
        "--colors=line:style:bold"
      ];
    };

    ripgrep-all.enable = config.${top}.inputs.applications.utilities.grep.enable;

    fd = {
      enable = config.${top}.inputs.applications.utilities.grep.enable;
      extraOptions = ["--absolute-path"];
      ignores = [
        ".git/"
        "archives"
        "tmp"
        "temp"
        "*.bak"
      ];
    };
  };
  ${top}.output.programs = {
    ripgrep = config.programs.ripgrep;
    ripgrep-all = config.programs.ripgrep-all;
    fd = config.programs.fd;
  };
}
