{
  lib,
  pkgs,
  modulesPath,
  host,
  ...
}:
let
  inherit (lib.attrsets) mapAttrs hasAttrByPath;
  inherit (lib.lists) elem filter;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) isString splitString;
  inherit (host.interface) bootLoader bootLoaderTimeout;
  inherit (host) modules functionalities devices;
  inherit (host.packages) kernel;
  inherit (host.specs) gpu cpu;

  # GPU detection
  hasPrimaryGPU = gpu ? primary && gpu.primary ? brand;
  hasSecondaryGPU = gpu ? secondary && gpu.secondary ? brand;

  gpuAMD = hasPrimaryGPU && (gpu.primary.brand == "amd" || elem "amdgpu" functionalities);
  gpuNVIDIA =
    (hasPrimaryGPU && gpu.primary.brand == "nvidia")
    || (hasSecondaryGPU && gpu.secondary.brand == "nvidia")
    || elem "nvidia" functionalities;

  # Hybrid mode requires both GPUs configured
  hasHybridSetup =
    hasPrimaryGPU
    && hasSecondaryGPU
    && gpu.primary ? busId
    && gpu.secondary ? busId
    && (gpu.mode or null) == "hybrid";

  cpuAMD = cpu.brand == "amd";
  cpuIntel = cpu.brand == "intel";
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  services.xserver.videoDrivers = filter (d: d != "") [
    "modesetting"
    (if gpuAMD then "amdgpu" else "")
    (if gpuNVIDIA then "nvidia" else "")
  ];

  hardware = {
    enableAllFirmware = gpuAMD || gpuNVIDIA;
    amdgpu.initrd.enable = gpuAMD;

    nvidia = mkIf gpuNVIDIA {
      modesetting.enable = true;
      open = false;
      powerManagement.enable = true;

      prime = mkIf hasHybridSetup {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        amdgpuBusId = gpu.primary.busId;
        nvidiaBusId = gpu.secondary.busId;
      };
    };
  };

  assertions = [
    {
      assertion =
        if kernel != null && isString kernel then hasAttrByPath (splitString "." kernel) pkgs else true;
      message = "kernelPackages string '${kernel}' does not resolve to a valid attribute in pkgs";
    }
  ];

  boot = {
    # Loader Configuration
    loader = {
      efi.canTouchEfiVariables = elem "efi" functionalities;
      refind.enable = bootLoader == "refind";
      grub.enable = bootLoader == "grub";
      systemd-boot.enable = bootLoader == "systemd-boot";
      timeout = bootLoaderTimeout;
    };

    # Initrd Configuration
    initrd = {
      availableKernelModules = modules;
      luks.devices = mapAttrs (_: v: { device = v.device; }) devices.boot;
    };

    # Kernel Configuration
    kernelModules =
      if cpuIntel then
        [ "kvm-intel" ]
      else if cpuAMD then
        [ "kvm-amd" ]
      else
        [ ];
    kernelPackages = mkIf (kernel != null) kernel;
  };
}
