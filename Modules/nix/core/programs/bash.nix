{
  config,
  host,
  lix,
  top,
  ...
}:
let
  dom = "programs";
  mod = "bash";
  cfg = config.${top}.${dom}.${mod};
  user = host.users.data.primary or { };
  inherit (config.${top}.interface) shell;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.options.construction) mkEnable mkTrue;
  inherit (lix.modules.construction) mkIf;
in
{
  options.${top}.${dom}.${mod} = {
    enable = mkEnable {
      description = "Bourne Again Shell";
      condition = isIn "bash" ([ shell ] ++ (user.shells or [ ]));
    };
    blesh = mkTrue "ble.sh";
    undistractMe = mkTrue "Undistract Me";
  };

  config = mkIf cfg.enable {
    programs.${mod} = {
      inherit (cfg) enable;
      blesh.enable = cfg.blesh;
      undistractMe.enable = cfg.undistractMe;
    };
  };
}
