# hardware/filesystems.nix
{
  config,
  host,
  lib,
  lix,
  top,
  ...
}: let
  dom = "hardware";
  mod = "filesystems";
  cfg = config.${top}.inputs.${dom}.${mod};

  hw = host.hardware;
  storage = host.storage;

  inherit (lib.attrsets) mapAttrs;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool;

  payload = {
    assertions = [
      {
        assertion = !cfg.filesystemsRequired || hw.hasFilesystems;
        message = "No filesystem declarations found. Add host.devices.file for a real host, or set host.storage.filesystemsRequired = false for a template, container, or ephemeral target.";
      }
    ];

    fileSystems = mkIf cfg.enable (mapAttrs (
      _: fs:
        {
          inherit (fs) device fsType;
        }
        // (
          if fs.options or [] == []
          then {}
          else {inherit (fs) options;}
        )
    ) (host.devices.file or {}));

    swapDevices = mkIf cfg.enable (map (s: {inherit (s) device;}) (host.devices.swap or []));

    services.udisks2 = mkIf (cfg.enable && cfg.udisks) {
      enable = true;
      mountOnMedia = true;
    };
  };
  inherit (lix.modules.core.staging) mkStaged;
in {
  options.${top}.inputs.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = hw.hasFilesystems;};
    filesystemsRequired = mkOption {
      description = "Require host.devices.file to declare at least one filesystem";
      default = storage.filesystemsRequired;
      type = bool;
    };
    udisks = mkOption {
      description = "Enable udisks2 for automounting removable media";
      default = hw.hasGui;
      type = bool;
    };
  };

  config = mkMerge (mkStaged {inherit top payload;});
}
