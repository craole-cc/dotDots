{_, ...}: let
  __doc = ''
    Hardware capability normalisation.
    Derives boolean flags from `host.functionalities` and device specs,
    ensuring all hardware-related predicates are computed once in the schema.
  '';

  __exports = {
    internal = {inherit mkHardware normalizeCpu normalizeGpu defaults;};
    external = {
      mkHardwareSchema = mkHardware;
    };
  };

  inherit (_.attrsets.access) attrValues;
  inherit (_.attrsets.aggregation) recursiveUpdate;
  inherit (_.attrsets.transformation) filterAttrs;
  inherit (_.lists.access) elemAt head length;
  inherit (_.lists.predicates) any elem isIn;
  inherit (_.lists.selection) filter;
  inherit (_.types.predicates) isAttrs isList isString;
  inherit (_.strings.construction) splitString;
  inherit (_.strings.transformation) toLower;
  inherit (_.lists.enums.gui) desktopEnvironments windowManagers;
  inherit (_.lists.enums.hardware) functionalities;

  dualBootValues = [
    (functionalities.resolve "dualboot-windows")
    (functionalities.resolve "dualboot-macos")
  ];

  defaults = {
    hasEfi = false;
    hasAudio = false;
    hasBluetooth = false;
    hasPrinter = false;
    hasScanner = false;
    hasWebcam = false;
    hasVideocam = false;
    hasDualBoot = false;
    hasNetwork = false;
    hasFilesystems = false;
    hasGui = false;
    cpu = {};
    gpu = {
      mode = "single";
      primary = null;
      secondary = null;
    };
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

    Uses enum values directly to avoid hardcoded strings - dualboot
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
    # => { hasEfi = true; hasAudio = true; hasDualBoot = true; hasNetwork = true; hasGui = true; ... }
  ```
  */
  # Accept the current `specs` / `devices` layout alongside the legacy
  # top-level `cpu` / `gpu` host fields. The normalized values are the only
  # hardware records downstream modules should consume.
  normalizeCpu = {host}: let
    specs =
      if isAttrs (host.specs or null) && isAttrs (host.specs.cpu or null)
      then host.specs.cpu
      else {};
    legacy =
      if isAttrs (host.cpu or null)
      then host.cpu
      else {};
    devices =
      if isAttrs (host.devices or null) && isAttrs (host.devices.cpu or null)
      then host.devices.cpu
      else {};
    hardware =
      if isAttrs (host.hardware or null) && isAttrs (host.hardware.cpu or null)
      then host.hardware.cpu
      else {};
    cpu =
      recursiveUpdate
      (recursiveUpdate (recursiveUpdate specs devices) legacy)
      hardware;
    systemArch =
      if isString (host.system or null)
      then head (splitString "-" host.system)
      else null;
    arch =
      if isString (cpu.arch or null)
      then cpu.arch
      else if systemArch != null
      then systemArch
      else "x86_64";
    microarch =
      if isString (cpu.microarch or null)
      then toLower cpu.microarch
      else "";
    declared =
      if (cpu.x86_64_level or null) != null
      then cpu.x86_64_level
      else cpu.level or null;
    level =
      if elem declared ["v1" "v2" "v3" "v4"]
      then declared
      else if elem microarch ["znver4" "znver5"]
      then "v4"
      else if elem microarch ["znver1" "znver2" "znver3"]
      then "v3"
      else null;
  in
    cpu
    // {
      inherit arch level;
      inherit microarch;
    };

  normalizeGpuSource = source: let
    isGpuRecord = isAttrs source && (source ? brand || source ? busId || source ? model);
    records =
      if isList source
      then source
      else if isAttrs source
      then
        if isGpuRecord
        then [source]
        else attrValues (filterAttrs (name: _: !(elem name ["mode" "primary" "secondary"])) source)
      else [];
    flagged = role: filter (record: isAttrs record && (record.${role} or false)) records;
    direct = role:
      if isAttrs source && isAttrs (source.${role} or null)
      then source.${role}
      else if isAttrs source && isString (source.${role} or null)
      then {brand = source.${role};}
      else null;
    normalizeRecord = record:
      if isString record
      then {brand = toLower record;}
      else if isAttrs record
      then let
        clean = filterAttrs (name: _: !(elem name ["primary" "secondary"])) record;
        brand = clean.brand or null;
      in
        if isString brand
        then clean // {brand = toLower brand;}
        else clean
      else null;
    selected = role: positional:
      if direct role != null
      then normalizeRecord (direct role)
      else if flagged role != []
      then normalizeRecord (head (flagged role))
      else if isList source && length records > positional
      then normalizeRecord (elemAt records positional)
      else if positional == 0 && length records == 1
      then normalizeRecord (head records)
      else null;
  in {
    mode =
      if isAttrs source
      then source.mode or null
      else null;
    primary = selected "primary" 0;
    secondary = selected "secondary" 1;
  };

  normalizeGpu = {host}: let
    devicesRoot =
      if isAttrs (host.devices or null)
      then host.devices
      else {};
    specsRoot =
      if isAttrs (host.specs or null)
      then host.specs
      else {};
    devices = normalizeGpuSource (devicesRoot.gpu or null);
    legacy = normalizeGpuSource (host.gpu or null);
    specs = normalizeGpuSource (specsRoot.gpu or null);
    primary =
      if devices.primary != null
      then devices.primary
      else if legacy.primary != null
      then legacy.primary
      else specs.primary;
    secondary =
      if devices.secondary != null
      then devices.secondary
      else if legacy.secondary != null
      then legacy.secondary
      else specs.secondary;
    hasGpu = source: source.primary != null || source.secondary != null;
    hasDeclaredMode = source: source.mode != null && (hasGpu source || source.mode != "single");
    declaredMode =
      if hasDeclaredMode devices
      then devices.mode
      else if legacy.mode != null
      then legacy.mode
      else if hasDeclaredMode specs
      then specs.mode
      else if devices.mode != null
      then devices.mode
      else specs.mode;
  in {
    mode =
      if declaredMode != null
      then declaredMode
      else if secondary != null
      then "hybrid"
      else "single";
    inherit primary secondary;
  };

  mkHardware = {host}: let
    fun = host.functionalities or [];
    cpu = normalizeCpu {inherit host;};
    gpu = normalizeGpu {inherit host;};
    iface = host.interface or {};
    storage = host.devices.storage or {};
    boot = storage.boot or {};
    mounts = storage.mounts or {};
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
      hasVideoCam = isIn ["video" "webcam"] fun;
      hasDualBoot = isIn dualBootValues fun;
      hasNetwork = host.devices.network or [] != [];
      hasFilesystems = mounts != {};
      hasGui =
        any (desktop: desktop != "none" && isIn desktop (desktopEnvironments.values ++ windowManagers.values)) (iface.desktops or [])
        || (de != null && de != "none" && isIn de desktopEnvironments.values)
        || (wm != null && wm != "none" && isIn wm windowManagers.values);
      inherit cpu gpu;
      boot = {
        loader = iface.boot.loader or iface.bootLoader or defaults.boot.loader;
        timeout = iface.boot.timeout or iface.bootLoaderTimeout or defaults.boot.timeout;
        efiMount =
          iface.boot.efiMount or boot.efiSysMountPoint or (
            if mounts ? "/boot"
            then "/boot"
            else defaults.boot.efiMount
          );
        kernelPkg = host.packages.kernel or null;
        modules = host.modules or [];
      };
    };
in
  __exports.internal
  // {
    inherit __doc;
    __rootAliases = __exports.external;
  }
