{
  programs = {
    ripgrep = {
      enable = true;
      arguments = [
        "--max-columns-preview"
        "--colors=line:style:bold"
      ];
    };

    ripgrep-all.enable = true;

    fd = {
      enable = true;
      extraOptions = ["--absolute-path"];
      ignores = [".git/" "archives" "tmp" "temp" "*.bak"];
    };
  };
}
