{
  config,
  host,
  lib,
  lix,
  pkgs,
  top,
  ...
}: let
  dom = "services";
  mod = "vpn";
  cfg = config.${top}.${dom}.${mod};
  vpnCfg = host.access.vpn or {};

  inherit (lib.attrsets) listToAttrs;
  inherit (lix.lists.predicates) isIn;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) listOf str;
  inherit (pkgs) iproute2 iptables openvpn writeShellScript;

  #~@ Build a firejail-wrapped binary that runs inside the vpn netns
  mkWrapped = app: {
    name = app;
    value = {
      executable = getExe pkgs.${app};
      extraArgs = ["--netns=vpn"];
    };
  };
in {
  options.${top}.${dom}.${mod} = {
    enable =
      mkEnableOption mod
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

  config = mkIf cfg.enable {
    #~@ Step 1: create the vpn network namespace
    systemd.services.vpn-netns = {
      description = "Create VPN network namespace";
      wantedBy = ["multi-user.target"];
      before = ["vpn-veth.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${iproute2}/bin/ip netns add vpn";
        ExecStop = "${iproute2}/bin/ip netns del vpn";
      };
    };

    #~@ Step 2: veth pair bridges main → vpn namespace
    systemd.services.vpn-veth = {
      description = "Bridge main namespace to VPN namespace";
      wantedBy = ["multi-user.target"];
      after = ["vpn-netns.service"];
      requires = ["vpn-netns.service"];
      before = ["vpn-tunnel.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = writeShellScript "vpn-veth-up" ''
          ${iproute2}/bin/ip link add veth-vpn0 type veth peer name veth-vpn1
          ${iproute2}/bin/ip link set veth-vpn1 netns vpn
          ${iproute2}/bin/ip addr add 10.200.200.1/24 dev veth-vpn0
          ${iproute2}/bin/ip link set veth-vpn0 up
          ${iproute2}/bin/ip netns exec vpn ${iproute2}/bin/ip addr add 10.200.200.2/24 dev veth-vpn1
          ${iproute2}/bin/ip netns exec vpn ${iproute2}/bin/ip link set veth-vpn1 up
          ${iproute2}/bin/ip netns exec vpn ${iproute2}/bin/ip link set lo up
          ${iproute2}/bin/ip netns exec vpn ${iproute2}/bin/ip route add default via 10.200.200.1
          ${iptables}/bin/iptables -t nat -A POSTROUTING -s 10.200.200.0/24 -j MASQUERADE
        '';
        ExecStop = writeShellScript "vpn-veth-down" ''
          ${iptables}/bin/iptables -t nat -D POSTROUTING -s 10.200.200.0/24 -j MASQUERADE || true
          ${iproute2}/bin/ip link del veth-vpn0 || true
        '';
      };
    };

    #~@ Step 3: OpenVPN runs inside the vpn namespace
    systemd.services.vpn-tunnel = {
      description = "OpenVPN inside VPN network namespace";
      wantedBy = ["multi-user.target"];
      after = ["vpn-veth.service"];
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

    #~@ Step 4: wrap target apps via firejail → vpn netns
    programs.firejail = {
      enable = cfg.apps != [];
      wrappedBinaries = listToAttrs (map mkWrapped cfg.apps);
    };

    #~@ Required kernel settings
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    environment.systemPackages = [openvpn];
  };
}
