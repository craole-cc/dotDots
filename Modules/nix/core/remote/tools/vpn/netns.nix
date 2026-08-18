{
  config,
  lix,
  pkgs,
  ...
}: let
  inherit (lix.modules.construction) mkContext mkConfig;
  inherit (pkgs) iproute2 iptables writeShellScript;

  context = mkContext {
    inherit config;
    dom = "remote";
    sub = "tools";
    mod = "vpn-netns";
  };

  vpnRoot = config.${context.top}.resolved.remote.tools;
  openvpnEnabled = vpnRoot.vpn-openvpn.explicit.enable or false;
  # wireguardEnabled = vpnRoot.vpn-wireguard.explicit.enable or false;
  anyBackendEnabled = openvpnEnabled; # || wireguardEnabled;
in
  mkConfig {
    inherit context;
    predicate = anyBackendEnabled;
    options = {};
    outputs.systemd.services = {
      vpn-netns = {
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
      vpn-veth = {
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
    };
  }
