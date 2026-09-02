{
  config,
  host,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "hardware";
    mod = "filesystems";
  };
  inherit (context) cfg;

  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.modules.construction) mkConfig mkContext mkIf;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.primitives) bool;

  hw = host.hardware;
  inherit (host) storage;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        description = "Filesystem and swap device configuration";
        condition = hw.hasFilesystems;
      };
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
    outputs = {
      assertions = [
        {
          assertion = !cfg.filesystemsRequired || hw.hasFilesystems;
          message = "No filesystem declarations found. Add host.devices.file for a real host, or set host.storage.filesystemsRequired = false for a template, container, or ephemeral target.";
        }
      ];

      fileSystems = mkIf cfg.enable (
        mapAttrs (
          _: fs:
            {
              inherit (fs) device fsType;
            }
            // (
              if fs.options or [] == []
              then {}
              else {inherit (fs) options;}
            )
        ) (host.devices.file or {})
      );

      swapDevices = mkIf cfg.enable (map (s: {inherit (s) device;}) (host.devices.swap or []));

      services.udisks2 = mkIf (cfg.enable && cfg.udisks) {
        enable = true;
        mountOnMedia = true;
      };
    };
  }
