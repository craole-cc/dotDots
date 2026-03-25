{
  config,
  lix,
  top,
  ...
}: let
  dom = "programs";
  mod = "git";
  cfg = config.${top}.${dom}.${mod};
  inherit (lix.options) mkTrue mkIf;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkTrue "Git";
    lfs = mkTrue "lfs";
    prompt = mkTrue "prompt";
  };

  config = mkIf cfg.enable {
    programs = {
      ${mod} = {
        enable = true;
        lfs.enable = true;
        prompt.enable = true;
      };
    };
  };
}
