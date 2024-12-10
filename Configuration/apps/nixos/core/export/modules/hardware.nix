{
  specialArgs,
  config,
  lib,
  ...
}:
let
  inherit (specialArgs.host) modules cpu devices;
in
{
  boot = {
    initrd = {
      availableKernelModules = modules;
      luks.devices = devices.luks;
    };

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    kernelModules =
      let
        inherit (cpu) brand;
      in
      if
        (elem brand [
          "intel"
          "amd"
          "x86"
        ])
      then
        [ "kvm-${brand}" ]
      else
        [ ];
    extraModulePackages = [ ];
  };

  inherit (devices) fileSystems swapDevices;

  networking = {
    hostId = id;
    hostName = name;
    # interfaces = {
    #   eno1.useDHCP = true;
    #   wlp3s0.useDHCP = true;
    # };
    interfaces =
      lib.mapAttrs
        (_: iface: {
          useDHCP = true;
        })
        (
          lib.listToAttrs (
            map (iface: {
              name = iface;
              value = { };
            }) devices.network
          )
        );

    firewall = {
      enable = false;
      # allowedTCPPorts = [ ... ];
      # allowedUDPPorts = [ ... ];
    };
  };
}
