{
  config,
  lix,
  lib,
  top,
  ...
}: let
  dom = "programs";
  mod = "starship";
  cfg = config.${top}.inputs.${dom}.${mod};

  # shell.prompt is declared by options.nix via mkOptions and defaults to
  # "starship" from the schema, so this condition is false only when the
  # host explicitly selects a different prompt.
  prompt = config.${top}.inputs.interface.shell.prompt or null;

  inherit (lix.options.construction) mkEnable;
  inherit (lix.modules.construction) mkIf;
  payload = {programs.${mod} = {inherit (cfg) enable;};  };
  inherit (lix.modules.core.staging) mkStaged;
in {
  options.${top}.inputs.${dom}.${mod} = {
    enable = mkEnable {
      description = "Starship Prompt";
      condition = prompt == "starship";
    };
  };

  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = cfg.enable;
  });
}
