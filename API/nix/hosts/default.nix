(import ../lib.nix).importAttrs {
  defaults = {
    imports = []; #? Extra Nix files or modules to import
    stateVersion = null; #? REQUIRED: NixOS state version (e.g. "25.05")
    system = null; #? REQUIRED: Target system architecture (e.g. "x86_64-linux", "aarch64-linux")
    class = null; #? REQUIRED: System classification (e.g. "nixos", "home-manager")
    id = null; #? AUTO-GENERATED: Unique host hash ID if omitted

    paths = {
      src = "/etc/nixos"; #? System flake location path
      wallpapers = null; #? Path to wallpaper directory or image file
    };

    modules = []; #? List of custom NixOS/home-manager module names to enable

    specs = {
      machine = null; #? Machine form factor (e.g. "desktop", "laptop", "server", "vm")
      cpu = {
        arch = null; #? REQUIRED: CPU architecture type (e.g. "x86_64", "aarch64")
        brand = null; #? REQUIRED: CPU manufacturer (e.g. "amd", "intel", "ampere")
        powerMode = null; #? Power management profile (e.g. "performance", "powersave", "balanced")
        cores = null; #? REQUIRED: Total number of physical/logical CPU cores
      };
      gpu = {
        primary = null; #? Primary GPU identifier/driver (e.g. "nvidia", "amd", "intel")
        secondary = null; #? Secondary GPU identifier (for hybrid graphics setups)
        mode = null; #? GPU operational mode (e.g. "hybrid", "integrated", "discrete")
      };
    };

    devices = {
      storage = {
        boot = {}; #? Boot partition/loader device configuration
        mounts = {}; #? Filesystem mounts and block device layout
        swap = []; #? List of swap devices or swap files
      };
      network = []; #? Network interface hardware devices
      display = {}; #? Display monitors, outputs, and resolutions
    };

    localization = {
      latitude = 18.015; #? Geographic latitude for night light / geolocation
      longitude = -77.49; #? Geographic longitude for night light / geolocation
      city = "Mandeville, Jamaica"; #? City name identifier
      locator = null; #? Custom location locator code like "geoclue2"
      timeZone = "America/Jamaica"; #? System time zone
      defaultLocale = "en_US.UTF-8"; #? Primary locale configuration
    };

    functionalities = []; #? High-level functional features to enable (e.g. ["gaming", "virtualization"])

    access = {
      ssh = null; #? Host SSH public key string
      age = null; #? Host age key string for secret management (SOPS/agenix)
      remote = {
        ssh = {
          enable = true; #? Enable SSH server access
          keyOnly = true; #? Restrict SSH access to pubkey authentication only
        };
        tailscale = {
          enable = true; #? Enable Tailscale mesh VPN daemon
        };
        caddy = {
          enable = false; #? Enable Caddy reverse proxy server
        };
      };
      firewall = {
        enable = true; #? Firewall enabled by default for safe baseline
        trustedInterfaces = [
          #? Trust Tailscale traffic automatically
          "tailscale0"
        ];
        tcp = {
          ranges = []; #? Keep empty; set per-host if needed
          ports = []; #? Keep empty; modules/hosts add what they use
        };
        udp = {
          ranges = []; #? Keep empty
          ports = []; #? Keep empty
        };
      };
      nameservers = [
        "1.1.1.1" #? Fallback DNS resolver if Tailscale is offline
        "1.0.0.1"
      ];
      vpn = {
        configFile = null; #? Path to host-specific VPN configuration file
        apps = []; #? Applications routed exclusively through VPN
      };
    };

    network = {
      backend = "networkmanager"; #? Network management backend (e.g. "networkmanager", "systemd-networkd")
    };

    principals = []; #? Primary system user profiles and administrative accounts

    interface = {
      bootLoader = "systemd-boot"; #? Boot loader selector (e.g. "systemd-boot", "grub")
      bootLoaderTimeout = 1; #? Boot menu timeout delay in seconds
      displayManager = null; #? Display manager service (e.g. "sddm", "gdm", "lightdm")
      desktopEnvironment = null; #? Desktop environment (e.g. "plasma", "gnome", "xfce")
      windowManager = null; #? Standalone window manager (e.g. "hyprland", "sway", "i3")
      displayProtocol = "wayland"; #? Display server protocol ("wayland" or "x11")
      keyboard = {
        modifier = "SUPER"; #? Main window manager modifier key ("SUPER" or "ALT")
        swapCapsEscape = false; #? Remap Caps Lock key to Escape key
      };
    };
  };
  required = [
    ["paths" "src"]
    ["stateVersion"]
    ["system"]
    ["class"]
    ["specs" "cpu" "arch"]
    ["specs" "cpu" "brand"]
    ["specs" "cpu" "cores"]
  ];
  target = ./.;
}
