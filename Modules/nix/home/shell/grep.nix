{config, lib, lix, top, ...}: let
  inherit (lix.modules.core.staging) mkStaged;
  payload = {

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
  };
in {
  config = lib.mkMerge (mkStaged {inherit top payload;});
}
