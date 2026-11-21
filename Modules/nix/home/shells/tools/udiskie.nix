{
  osConfig ? {},
  pkgs,
  lix,
  ...
}: let
  inherit (lix.modules.construction) mkIf;
  phonePython = pkgs.python3.withPackages (packages: [packages.pygobject3]);
in {
  services.udiskie = {
    enable = osConfig.services.udisks2.enable or false;
    automount = true;
    notify = true;
    tray = "auto";
    settings = {
      program_options = {
        udisks_version = 2;
        tray = "auto";
        notify = true;
        menu = "flat";
      };
      # Opt internal data volumes into the same policy as removable media.
      # Keep UDisks exclusions and udiskie's non-block-device safeguards.
      device_config = [
        {
          is_loop = true;
          ignore = true;
        }
        {
          is_ignored = true;
          ignore = true;
        }
        {
          is_block = true;
          is_filesystem = true;
          ignore = false;
        }
        {
          is_block = true;
          is_crypto = true;
          ignore = false;
        }
      ];
      icon_names = {
        media = [
          "drive-removable-media"
          "media-optical"
        ];
        browse = [
          "document-open"
          "folder-open"
        ];
        terminal = [
          "terminal"
          "terminator"
          "xfce-terminal"
        ];
        mount = ["udiskie-mount"];
        unmount = ["udiskie-unmount"];
        unlock = ["udiskie-unlock"];
        lock = ["udiskie-lock"];
        eject = [
          "udiskie-eject"
          "media-eject"
        ];
        detach = ["udiskie-detach"];
        delete = ["udiskie-eject"];
        quit = ["application-exit"];
      };
    };
  };
  systemd.user.services.phone-automount = mkIf (osConfig.services.gvfs.enable or false) {
    Unit = {
      Description = "Mount connected phone storage through GVfs";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${phonePython}/bin/python ${./phone-automount.py}";
      Environment = [
        "GI_TYPELIB_PATH=${pkgs.glib.out}/lib/girepository-1.0"
        "GIO_EXTRA_MODULES=${osConfig.services.gvfs.package}/lib/gio/modules"
      ];
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
