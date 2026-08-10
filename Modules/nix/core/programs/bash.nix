{
  config,
  lix,
  lib,
  top,
  ...
}: let
  dom = "programs";
  mod = "bash";
  cfg = config.${top}.inputs.${dom}.${mod};

  # shell.interactive is declared by options.nix via mkOptions and defaults
  # to "bash" from the schema, so this condition is false only when the host
  # explicitly selects a different interactive shell.
  shell = config.${top}.inputs.interface.shell.interactive or null;

  inherit (lix.lists.predicates) isIn;
  inherit (lix.options.construction) mkEnable mkTrue;
  inherit (lix.modules.construction) mkIf;
  payload = {
    programs.${mod} = {
      inherit (cfg) enable;
      blesh.enable = cfg.blesh;
      undistractMe.enable = cfg.undistractMe;
    };
    };
  inherit (lix.modules.core._) mkStaged;
in {
  options.${top}.inputs.${dom}.${mod} = {
    enable = mkEnable {
      description = "Bourne Again Shell";
      condition = isIn "bash" [shell];
    };
    blesh = mkTrue "ble.sh";
    undistractMe = mkTrue "Undistract Me";
  };

  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = cfg.enable;
  });
}
