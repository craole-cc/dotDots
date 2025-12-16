{_, ...}: let
  inherit (_.lists.generators) mkEnum;
  inherit (_.testing.unit) mkTest runTests;
  inherit (_.std.lists) length;

  /**
  Host functionalities - hardware and firmware capabilities.

  Defines what physical or firmware features are available on the system.
  Used for conditional configuration based on hardware presence.

  # Categories
  - Input: keyboard, touchpad, touchscreen
  - Storage: storage, nvme, ssd, hdd
  - Network: network, wired, wireless, bluetooth
  - Display: video, gpu, amdgpu, nvidiagpu, intelgpu
  - Audio: audio, speakers, microphone
  - Security: tpm, fingerprint, smartcard, secureboot
  - Power: battery, power-management
  - Virtualization: virtualization, kvm
  - Boot: efi, bios, dualboot-windows, dualboot-macos
  - Peripherals: webcam, printer, scanner

  # Structure
  ```nix
  {
    values = [ ... ];      # List of valid functionality names
    validator = { ... };   # Case-insensitive validator
  }
  ```

  # Usage
  ```nix
  # Check if a functionality is valid
  _lib.hostFunctionalities.validator.check { name = "bluetooth"; }  # => true

  # Get all valid functionalities
  _lib.hostFunctionalities.values
  ```
  */
  functionalities = mkEnum [
    #~@ Input devices
    "keyboard"
    "touchpad"
    "touchscreen"

    #~@ Storage
    "storage"
    "nvme"
    "ssd"
    "hdd"

    #~@ Network
    "network"
    "wired"
    "wireless"
    "bluetooth"

    #~@ Display
    "video"
    "gpu"
    "amdgpu"
    "nvidiagpu"
    "intelgpu"

    #~@ Audio
    "audio"
    "speakers"
    "microphone"

    #~@ Security
    "tpm"
    "fingerprint"
    "smartcard"
    "secureboot"

    #~@ Power
    "battery"
    "power-management"

    #~@ Virtualization
    "virtualization"
    "kvm"

    #~@ Boot
    "efi"
    "bios"
    "dualboot-windows"
    "dualboot-macos"

    #~@ Peripherals
    "webcam"
    "printer"
    "scanner"
  ];

  /**
  CPU brands - processor manufacturer identification.

  Identifies the CPU vendor for architecture-specific optimizations
  and driver selection.

  # Supported Brands
  - amd: AMD processors (Ryzen, EPYC, Threadripper)
  - intel: Intel processors (Core, Xeon, Pentium)
  - arm: ARM-based processors (Apple Silicon, Snapdragon)
  - risc-v: RISC-V architecture processors

  # Structure
  ```nix
  {
    values = [ "amd" "intel" "arm" "risc-v" ];
    validator = { check, list };
  }
  ```

  # Usage
  ```nix
  # Validate a CPU brand
  _lib.cpuBrands.validator.check { name = "AMD"; }  # => true (case-insensitive)

  # Check if value is in list
  _lib.inList "amd" _lib.cpuBrands.values
  ```
  */
  cpuBrands = mkEnum ["amd" "intel" "arm" "risc-v"];

  /**
  CPU power modes - processor power management profiles.

  Defines power/performance trade-off profiles for CPU governor configuration.

  # Modes
  - performance: Maximum performance, higher power consumption
  - powerSaving: Maximum battery life, reduced performance
  - balanced: Optimal balance between performance and power

  # Structure
  ```nix
  {
    values = [ "performance" "powerSaving" "balanced" ];
    validator = { check, list };
  }
  ```

  # Usage
  ```nix
  # Validate power mode selection
  _lib.cpuPowerModes.validator.check { name = "Performance"; }  # => true
  ```
  */
  cpuPowerModes = mkEnum [
    "performance"
    "powerSaving"
    "balanced"
  ];

  /**
  GPU brands - graphics card manufacturer identification.

  Identifies the GPU vendor for driver selection and hardware acceleration.

  # Supported Brands
  - amd: AMD Radeon graphics
  - intel: Intel integrated/discrete graphics
  - nvidia: NVIDIA GeForce/Quadro graphics

  # Structure
  ```nix
  {
    values = [ "amd" "intel" "nvidia" ];
    validator = { check, list };
  }
  ```

  # Usage
  ```nix
  # Validate GPU brand
  _lib.gpuBrands.validator.check { name = "NVIDIA"; }  # => true

  # Check multiple GPUs
  _lib.areAllInList ["amd" "intel"] _lib.gpuBrands.values true
  ```
  */
  gpuBrands = mkEnum [
    "amd"
    "intel"
    "nvidia"
  ];
in {
  inherit functionalities gpuBrands cpuBrands cpuPowerModes;

  _rootAliases = {
    hostFunctionalities = functionalities;
  };

  _tests = runTests {
    functionalities = {
      validatesCommon = mkTest true (functionalities.validator.check "keyboard");
      validatesStorage = mkTest true (functionalities.validator.check "nvme");
      validatesSecurity = mkTest true (functionalities.validator.check "tpm");
    };

    cpuBrands = {
      validatesAMD = mkTest true (cpuBrands.validator.check "amd");
      validatesIntel = mkTest true (cpuBrands.validator.check "intel");
      correctCount = mkTest 4 (length cpuBrands.values);
    };

    cpuPowerModes = {
      validatesPerformance = mkTest true (cpuPowerModes.validator.check "performance");
      validatesPowerSaving = mkTest true (cpuPowerModes.validator.check "powersaving");
      validatesBalanced = mkTest true (cpuPowerModes.validator.check "balanced");
      correctCount = mkTest 3 (length cpuPowerModes.values);
    };

    gpuBrands = {
      validatesNvidia = mkTest true (gpuBrands.validator.check "nvidia");
      validatesAmd = mkTest true (gpuBrands.validator.check "amd");
      validatesIntel = mkTest true (gpuBrands.validator.check "intel");
      correctCount = mkTest 3 (length gpuBrands.values);
    };
  };
}
