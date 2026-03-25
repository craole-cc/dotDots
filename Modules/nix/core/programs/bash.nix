{
  config,
  host,
  lix,
  top,
  ...
}: let
  dom = "programs";
  mod = "bash";
  cfg = config.${top}.${dom}.${mod};
  user = host.users.data.primary or {};
  inherit (config.${top}.interface) shell;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.types.options) mkEnable mkTrue mkIf;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnable {
      description = "Bourne Again Shell";
      condition = isIn "bash" ([shell] ++ (user.shells or []));
    };
    # blesh = mkTrue "ble.sh";
    # undistractMe = mkTrue "Undistract Me";
    blesh = mkEnable {description = "ble.sh";};
    undistractMe = mkEnable {description = "Undistract Me";};
  };

  config = mkIf cfg.enable {
    programs.${mod} = {
      enable = true;
      blesh.enable = cfg.blesh.enable;
      undistractMe.enable = cfg.undistractMe.enable;
    };
  };
}
