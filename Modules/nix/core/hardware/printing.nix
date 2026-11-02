{
  config,
  host,
  lix,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.lists.predicates) isIn;

  context = mkContext {
    inherit config;
    dom = "hardware";
    mod = "printing";
  };
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        inherit context;
        condition = isIn "printer" (host.functionalities or []);
      };
    };
    outputs = {
      services = {
        printing.enable = true;
        avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };
        ipp-usb.enable = true;
      };
    };
  }
