{
  config,
  lix,
  pkgs,
  user,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.lists.predicates) isIn;

  context = mkContext {
    inherit config;
    dom = "info";
    mod = "fastfetch";
  };
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = isIn "fastfetch" (user.applications.allowed or []);
    };
    outputs = {
      home.packages = with pkgs; [
        countryfetch
        freshfetch
        gitfetch
        hyfetch
        ipfetch
        macchina
        nitch
        onefetch
        owofetch
        pfetch-rs
        ramfetch
        starfetch
        tokei
        ufetch
      ];

      programs.fastfetch = {
        enable = true;
        settings = {
          # logo = {
          #   source = "nixos_small";
          #   padding.right = 1;
          # };
        };
      };
    };
  }
