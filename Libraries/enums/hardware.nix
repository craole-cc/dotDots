{_, ...}: let
  mkVal = _.lists.makeCaseInsensitiveListValidator;

  /**
  Host functionalities - hardware and firmware capabilities.

  Defines what physical or firmware features are available on the system.
  Used for conditional configuration based on hardware presence.

  # Categories
  - Input devices: keyboard, touchpad, touchscreen
  - Storage: storage, nvme
  - Network: network, wired, wireless, bluetooth
  - Display: video, gpu, amdgpu
  - Audio: audio
  - Security: tpm, fingerprint, smartcard, secureboot
  - Power: battery
  - Virtualization: virtualization
  - Boot: efi, dualboot-windows
  - Peripherals: webcam

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
  functionalities = let
    values = [
      "keyboard"
      "storage"
      "network"
      "video"
      "virtualization"
      "audio"
      "bluetooth"
      "touchpad"
      "touchscreen"
      "wired"
      "wireless"
      "dualboot-windows"
      "efi"
      "secureboot"
      "tpm"
      "battery"
      "webcam"
      "fingerprint"
      "smartcard"
      "gpu"
      "amdgpu"
      "nvme"
    ];
  in {
    inherit values;
    validator = mkVal values;
  };

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
  cpuBrands = let
    values = [
      "amd"
      "intel"
      "arm"
      "risc-v"
    ];
  in {
    inherit values;
    validator = mkVal values;
  };

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
  cpuPowerModes = let
    values = [
      "performance"
      "powerSaving"
      "balanced"
    ];
  in {
    inherit values;
    validator = mkVal values;
  };

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
  gpuBrands = let
    values = [
      "amd"
      "intel"
      "nvidia"
    ];
  in {
    inherit values;
    validator = mkVal values;
  };
in {
  inherit functionalities gpuBrands cpuBrands cpuPowerModes;
  _rootAliases = {
    hostFunctionalities = functionalities;
  };
}
