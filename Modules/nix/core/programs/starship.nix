{
  config,
  lix,
  top,
  ...
}: let
  dom = "programs";
  mod = "starship";
  cfg = config.${top}.${dom}.${mod};

  # shell.prompt is declared by options.nix via mkOptions and defaults to
  # "starship" from the schema, so this condition is false only when the
  # host explicitly selects a different prompt.
  prompt = config.${top}.interface.shell.prompt or null;

  inherit (lix.options.construction) mkEnable;
  inherit (lix.modules.construction) mkIf;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnable {
      description = "Starship Prompt";
      condition = prompt == "starship";
    };
  };

  config = mkIf cfg.enable {programs.${mod} = {inherit (cfg) enable;};};
}
