# hardware/filesystems.nix
{
  config,
  host,
  lib,
  top,
  ...
}: let
  dom = "hardware";
  mod = "filesystems";
  cfg = config.${top}.${dom}.${mod};

  hw = host.hardware;

  inherit (lib.attrsets) mapAttrs;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = true;};
    udisks = mkOption {
      description = "Enable udisks2 for automounting removable media";
      default = hw.hasGui;
      type = bool;
    };
  };

  config = mkIf cfg.enable {
    fileSystems = mapAttrs (_: fs:
      {
        device = fs.device;
        fsType = fs.fsType;
      }
      // (
        if fs.options or [] == []
        then {}
        else {options = fs.options;}
      ))
    (host.devices.file or {});

    swapDevices = map (s: {device = s.device;}) (host.devices.swap or []);

    services.udisks2 = mkIf cfg.udisks {
      enable = true;
      mountOnMedia = true;
    };
  };
}
