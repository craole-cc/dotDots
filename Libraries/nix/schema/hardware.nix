{_, ...}: let
  __doc = ''
    Hardware capability normalization.
    Derives boolean flags from `host.functionalities` and device specs,
    ensuring all hardware-related predicates are computed once in the schema.
  '';

  __exports = {
    internal = {inherit mkHardware defaults;};
    external = {mkHardwareSchema = mkHardware;};
  };

  inherit (_.lists.predicates) isIn;
  inherit (_.enums) hostFunctionalities desktopEnvironments windowManagers;

  dualBootValues = [
    (hostFunctionalities.resolve "dualboot-windows")
    (hostFunctionalities.resolve "dualboot-macos")
  ];

  defaults = {
    hasEfi = false;
    hasAudio = false;
    hasBluetooth = false;
    hasPrinter = false;
    hasScanner = false;
    hasWebcam = false;
    dualBootWindows = false;
    hasDualBoot = false;
    hasNetwork = false;
    hasGui = false;
    boot = {
      loader = "systemd-boot";
      timeout = 5;
      efiMount = "/boot";
      kernelPkg = null;
      modules = [];
    };
  };

  /**
    Derive hardware capability flags from a host definition.

    Uses enum values directly to avoid hardcoded strings — dualboot
    variants are derived from `hostFunctionalities`, GUI detection
    uses `desktopEnvironments` and `windowManagers` enum values.

    # Type
  ```
    mkHardware :: { host :: AttrSet } -> AttrSet
  ```

    # Examples
  ```nix
    mkHardware {
      host = {
        functionalities = ["efi" "audio" "dualboot-windows"];
        devices.network = ["eth0"];
        interface.desktopEnvironment = "gnome";
      };
    }
    # => { hasEfi = true; hasAudio = true; dualBootWindows = true; hasDualBoot = true; hasNetwork = true; hasGui = true; ... }
  ```
  */
  mkHardware = {host}: let
    fun = host.functionalities or [];
    iface = host.interface or {};
    boot = host.devices.boot or {};
    de = iface.desktopEnvironment or null;
    wm = iface.windowManager or null;
  in
    defaults
    // {
      hasEfi = isIn "efi" fun;
      hasAudio = isIn "audio" fun;
      hasBluetooth = isIn "bluetooth" fun;
      hasPrinter = isIn "printer" fun;
      hasScanner = isIn "scanner" fun;
      hasWebcam = isIn "webcam" fun;
      dualBootWindows = isIn "dualboot-windows" fun;
      hasDualBoot = isIn dualBootValues fun;
      hasNetwork = host.devices.network or [] != [];
      hasGui =
        (de != null && de != "none" && isIn de desktopEnvironments.values)
        || (wm != null && wm != "none" && isIn wm windowManagers.values);
      boot = {
        loader = iface.bootLoader or defaults.boot.loader;
        timeout = iface.bootLoaderTimeout or defaults.boot.timeout;
        efiMount = boot.efiSysMountPoint or defaults.boot.efiMount;
        kernelPkg = host.packages.kernel or null;
        modules = host.modules or [];
      };
    };
in
  __exports.internal
  // {
    inherit __doc;
    _rootAliases = __exports.external;
  }
