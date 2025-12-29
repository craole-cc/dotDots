{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) genAttrs mapAttrs optionalAttrs;
  inherit (lib.lists) optionals;
  inherit (_.lists.predicates) isIn;
  hasAudio = host: isIn "audio" (host.functionalities or []);

  mkFileSystem = _: fs: let
    base = {
      device = fs.device;
      fsType = fs.fsType;
    };
    opts = fs.options or [];
  in
    #> Combine base attributes with options if they exist.
    if opts == []
    then base
    else base // {options = opts;};
  mkSwapDevice = s: {device = s.device;};

  mkFileSystems = {host, ...}: {
    fileSystems = mapAttrs mkFileSystem (host.devices.file or {});
    swapDevices = map mkSwapDevice (host.devices.swap or []);
  };

  mkAudio = {host, ...}: {
    services = optionalAttrs (hasAudio host) {
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
      };
      pulseaudio.enable = false;
    };
    security = optionalAttrs (hasAudio host) {rtkit.enable = true;};
  };

  mkNetwork = {
    host,
    pkgs,
    gnupgSupported ? true,
    ...
  }: let
    networkDevices = host.devices.network or [];
    hasNetwork = networkDevices != [];
    access = host.access or {};
    firewall = access.firewall or {};
  in {
    networking = {
      hostName = host.name or "nixos";
      hostId = host.id or null;
      networkmanager.enable = hasNetwork;
      nameservers = access.nameservers or [];
      interfaces = genAttrs networkDevices (_: {useDHCP = hasNetwork;});
      firewall = {
        enable = firewall.enable or false;
        allowedTCPPorts = firewall.tcp.ports or [];
        allowedTCPPortRanges = firewall.tcp.ranges or [];
        allowedUDPPorts = firewall.udp.ports or [];
        allowedUDPPortRanges = firewall.udp.ranges or [];
      };
    };

    environment.systemPackages = optionals hasNetwork (with pkgs; [
      speedtest-cli
      speedtest-go
      mtr
      curl
      wget
      tldr
    ]);

    programs = {
      gnupg = optionalAttrs gnupgSupported {
        agent = {
          enable = true;
          enableSSHSupport = true;
        };
      };
    };
  };
  exports = {
    inherit
      mkFileSystem
      mkFileSystems
      mkSwapDevice
      mkAudio
      mkNetwork
      ;
  };
in
  exports // {_rootAliases = exports;}
