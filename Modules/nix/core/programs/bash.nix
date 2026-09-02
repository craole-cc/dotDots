{
  config,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "programs";
    mod = "bash";
  };
  inherit (context) cfg mod top;

  inherit (lix.lists.predicates) isIn;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkTrue;

  shell = config.${top}.resolved.interface.shell.interactive or null;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        description = "Bourne Again Shell";
        condition = isIn "bash" [shell];
      };
      blesh = mkTrue "ble.sh";
      undistractMe = mkTrue "Undistract Me";
    };
    outputs = {
      programs.${mod} = {
        inherit (cfg) enable;
        blesh.enable = cfg.blesh;
        undistractMe.enable = cfg.undistractMe;
      };
    };
  }
