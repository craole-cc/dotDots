{
  apps,
  config,
  lix,
  pkgs,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  context = mkContext {
    inherit config;
    dom = "environment";
    mod = "sysinfo";
  };
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = apps.needs "fastfetch";
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
