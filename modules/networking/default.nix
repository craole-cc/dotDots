{
  config,
  lib,
  ...
}: let
  cfg = config.zfs-root.networking;
  inherit (lib) types mkDefault mkOption mkIf mkMerge mapAttrsToList;
in {
  options.zfs-root.networking = {
    networkmanager = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
      wirelessNetworks = mkOption {
        description = "configure wireless networks with NetworkManager";
        type = types.attrsOf types.str;
        default = {};
        example = {"network_ssid" = "password";};
      };
    };
    hostName = mkOption {
      description = "The name of the machine.  Used by nix flake.";
      type = types.str;
      default = "exampleHost";
    };
    timeZone = mkOption {
      type = types.str;
      default = "Etc/UTC";
    };
    hostId = mkOption {
      description = "Set host id";
      type = types.str;
    };
  };
  config = {
    networking.hostId = cfg.hostId;
    time.timeZone = cfg.timeZone;
    networking = {
      firewall.enable = mkDefault true;
      hostName = cfg.hostName;
      networkmanager = {
        enable = cfg.networkmanager.enable;
        wifi = {macAddress = mkDefault "random";};
      };
    };
    environment.etc = mkIf cfg.networkmanager.enable (mkMerge (mapAttrsToList
      (name: pwd: {
        "NetworkManager/system-connections/${name}.nmconnection" = {
          # networkmanager demands secure permission
          mode = "0600";
          text = ''
            [connection]
            id=${name}
            type=wifi

            [wifi]
            mode=infrastructure
            ssid=${name}

            [wifi-security]
            auth-alg=open
            key-mgmt=wpa-psk
            psk=${pwd}
          '';
        };
      })
      cfg.networkmanager.wirelessNetworks));
  };
}
