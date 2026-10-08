{
  config,
  host,
  lix,
  ...
}: let
  inherit (lix.modules.construction) mkContext mkConfig;
  inherit (lix.options.construction) mkOption mkEnableOption;
  inherit (lix.lists.predicates) isIn;
  portRanges = with lix.types.combinators; listOf attrs;
  tailscaleInterface = "tailscale0";

  context = mkContext {
    inherit config;
    dom = "remote";
    sub = "core";
    mod = "tailscale";
  };
  inherit (context) cfg;
in
  mkConfig {
    inherit context;
    options = {
      enable =
        mkEnableOption "Enable Tailscale remote access"
        // {
          default =
            host.access.remote.tailscale.enable or (
              host.access.tailscale.enable or (
                isIn "vpn" (host.functionalities or [])
              )
            );
        };

      firewall = {
        tcp.ranges = mkOption {
          description = "TCP port ranges allowed on the Tailscale interface";
          default = host.access.tailscale.firewall.tcp.ranges or [];
          type = portRanges;
        };
        udp.ranges = mkOption {
          description = "UDP port ranges allowed on the Tailscale interface";
          default = host.access.tailscale.firewall.udp.ranges or [];
          type = portRanges;
        };
      };
    };

    outputs = {
      services.tailscale.enable = cfg.enable;
      networking.firewall.interfaces.${tailscaleInterface} = {
        allowedTCPPortRanges = cfg.firewall.tcp.ranges;
        allowedUDPPortRanges = cfg.firewall.udp.ranges;
      };
    };
  }
