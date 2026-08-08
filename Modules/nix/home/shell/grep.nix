{config, top, ...}: {
  programs = {
    ripgrep = {
      enable = config.${top}.applications.utilities.grep.enable;
      arguments = [
        "--max-columns-preview"
        "--colors=line:style:bold"
      ];
    };

    ripgrep-all.enable = config.${top}.applications.utilities.grep.enable;

    fd = {
      enable = config.${top}.applications.utilities.grep.enable;
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
}
