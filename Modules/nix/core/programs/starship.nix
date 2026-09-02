{
  config,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "programs";
    mod = "starship";
  };
  inherit (context) cfg mod top;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  # shell.prompt defaults to "starship" from the schema (see options.nix),
  # so this condition is false only when the host explicitly selects a
  # different prompt.
  prompt = config.${top}.resolved.interface.shell.prompt or null;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        description = "Starship Prompt";
        condition = prompt == "starship";
      };
    };
    outputs = {
      programs.${mod} = {inherit (cfg) enable;};
    };
  }
