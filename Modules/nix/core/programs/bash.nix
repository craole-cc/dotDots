{
  config,
  host,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "programs";
    mod = "bash";
  };
  inherit (context) cfg mod top;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkTrue;

  shell = host.interface.shell.interactive or null;
  lineEditor = host.interface.shell.lineEditor or null;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        description = "Bourne Again Shell";
        condition = shell == "bash";
      };
      blesh = mkEnable {
        description = "ble.sh";
        condition = lineEditor == "blesh";
      };
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
