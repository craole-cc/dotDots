{
  config,
  host,
  lix,
  pkgs,
  ...
}: let
  inherit (lix.modules.construction) mkContext mkConfig;
  inherit (lix.options.construction) mkEnableOption mkOption;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.types.combinators) listOf;
  inherit (lix.types.primitives) str;
  inherit (pkgs) iproute2 openvpn writeShellScript;

  context = mkContext {
    inherit config;
    dom = "remote";
    sub = "tools";
    mod = "vpn-openvpn";
  };
  inherit (context) cfg;
  vpnCfg = host.access.vpn or {};
in
  mkConfig {
    inherit context;
    options = {
      enable =
        mkEnableOption "OpenVPN namespace-isolated tunnel"
        // {
          default = isIn "vpn" (host.functionalities or []);
        };
      configFile = mkOption {
        description = "Path to .ovpn config (outside Nix store)";
        default = vpnCfg.configFile or "/etc/openvpn/vpn.ovpn";
        type = str;
      };
      apps = mkOption {
        description = "Apps to route through the VPN namespace";
        default = vpnCfg.apps or [];
        type = listOf str;
      };
    };
    outputs = {
      systemd.services.vpn-tunnel = {
        description = "OpenVPN inside VPN network namespace";
        wantedBy = ["multi-user.target"];
        after = [
          "vpn-veth.service"
          "agenix.service"
        ];
        requires = ["vpn-veth.service"];
        serviceConfig = {
          Type = "simple";
          ExecStart = writeShellScript "vpn-start" ''
            exec ${iproute2}/bin/ip netns exec vpn \
              ${openvpn}/sbin/openvpn \
                --config ${cfg.configFile} \
                --auth-retry nointeract
          '';
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
      environment.systemPackages = [openvpn];
    };
  }
