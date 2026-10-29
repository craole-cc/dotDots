{
  config,
  lib,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lib.modules) mkMerge;
  inherit (lix.applications.generators) userApplicationConfig;

  context = mkContext {
    inherit config;
    dom = "editor";
    mod = "nvim";
    kind = "editor";
  };

  session = import ../helix/session {
    inherit config lix pkgs;
    editor = "neovim";
    command = "nvim";
    name = (lix.applications.registry.resolve {value = "neovim";}).launch.scratchpad;
  };

  resolved = userApplicationConfig {
    inherit context user pkgs;
    name = "nvf";
    category = "tty";
    extraPackages = [session];
    resolutionHints = [
      "neovim"
      "nvim"
    ];
    extraProgramConfig = mkMerge [
      # (import ./editor.nix)
      # (import ./keybindings.nix)
      # (import ./languages.nix)
      # (import ./themes.nix)
    ];
    debug = false;
  };
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = resolved.enable;
    };
    outputs = {inherit (resolved) home programs;};
  }
