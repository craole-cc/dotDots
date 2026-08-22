{
  config,
  host,
  lib,
  lix,
  pkgs,
  top,
  ...
}: let
  dom = "hardware";
  mod = "network";
  cfg = config.${top}.resolved.${dom}.${mod};

  hw = host.hardware;
  access = host.access or {};
  fw = access.firewall or {};

  inherit (lib.attrsets) genAttrs;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkEnableOption mkOption;
  inherit
    (lib.types)
    attrsOf
    bool
    enum
    int
    listOf
    nullOr
    str
    ;

  payload = {
    networking = {
      inherit (cfg) hostName hostId nameservers;
      networkmanager.enable = cfg.backend == "networkmanager";
      interfaces = genAttrs cfg.devices (_: {
        useDHCP = true;
      });
      firewall = {
        inherit (cfg.firewall) enable;
        allowedTCPPorts = cfg.firewall.tcpPorts;
        allowedTCPPortRanges = cfg.firewall.tcpRanges;
        allowedUDPPorts = cfg.firewall.udpPorts;
        allowedUDPPortRanges = cfg.firewall.udpRanges;
      };
    };

    programs.gnupg.agent = mkIf cfg.gnupg {
      enable = true;
      enableSSHSupport = true;
    };

    environment.systemPackages = with pkgs; [
      dig
      speedtest-cli
      speedtest-go
      mtr
      curl
      wget
      tldr
    ];
  };
  inherit (lix.modules.core.staging) mkStaged;
in {
  options.${top}.resolved.${dom}.${mod} = {
    enable =
      mkEnableOption mod
      // {
        default = hw.hasNetwork;
      };
    hostName = mkOption {
      description = "System hostname";
      default = host.name or "nixos";
      type = str;
    };
    hostId = mkOption {
      description = "System host ID";
      default = host.id or null;
      type = nullOr str;
    };
    nameservers = mkOption {
      description = "DNS nameservers";
      default = access.nameservers or [];
      type = listOf str;
    };
    devices = mkOption {
      description = "Network interface names";
      default = host.devices.network or [];
      type = listOf str;
    };
    backend = mkOption {
      description = "Network configuration backend";
      default = host.network.backend or "networkmanager";
      type = enum [
        "networkmanager"
        "networkd"
      ];
    };
    gnupg = mkOption {
      description = "Enable GnuPG agent with SSH support";
      default = true;
      type = bool;
    };
    firewall = {
      enable = mkOption {
        description = "Enable firewall";
        default = fw.enable or false;
        type = bool;
      };
      tcpPorts = mkOption {
        description = "Allowed TCP ports";
        default = fw.tcp.ports or [];
        type = listOf int;
      };
      tcpRanges = mkOption {
        description = "Allowed TCP port ranges";
        default = fw.tcp.ranges or [];
        type = listOf (attrsOf int);
      };
      udpPorts = mkOption {
        description = "Allowed UDP ports";
        default = fw.udp.ports or [];
        type = listOf int;
      };
      udpRanges = mkOption {
        description = "Allowed UDP port ranges";
        default = fw.udp.ranges or [];
        type = listOf (attrsOf int);
      };
    };
  };

  config = mkMerge (mkStaged {
    condition = cfg.enable;
    inherit top payload;
  });
}
