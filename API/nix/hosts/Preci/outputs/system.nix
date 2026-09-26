{
  config,
  lib,
  pkgs,
  args,
  inputs,
  resolved,
  ...
}: let
  inherit (lib.attrsets) listToAttrs;
  inherit (lib.lists) unique;

  principals = resolved.principals.all;
  primary = resolved.principals.primary;
  interface = resolved.interface;

  packageNames =
    unique (
      resolved.packages.common
      ++ resolved.packages.coding
      ++ resolved.packages.launchers
      ++ resolved.packages.shells
    );

  packages =
    builtins.filter
    (package: package != null)
    (map
      (name:
        if builtins.hasAttr name pkgs
        then pkgs.${name}
        else null)
      packageNames);

  userPackages = user:
    builtins.filter
    (package: package != null)
    (map
      (name:
        if builtins.hasAttr name pkgs
        then pkgs.${name}
        else null)
      (unique (
        user.packages.common
        ++ user.packages.coding
        ++ user.packages.launchers
        ++ user.packages.shells
      )));

  isDesktop = name: builtins.elem name interface.desktops;
  isFunctionality = name: builtins.elem name resolved.functionalities;

  catppuccinFlavor = flavor:
    if flavor == "Catppuccin Frappé" then "frappe"
    else if flavor == "Catppuccin Latte" then "latte"
    else lib.toLower flavor;

  darkFlavor = catppuccinFlavor (interface.themes.dark.flavor or "frappe");
  darkAccent = interface.themes.dark.accent or "mauve";

  users = listToAttrs (map (user: {
    name = user.name;
    value = {
      isNormalUser = true;
      description = user.description;
      hashedPassword = user.hashedPassword;
      extraGroups =
        if user.role == "administrator"
        then ["wheel" "networkmanager"]
        else ["networkmanager"];
    };
  }) principals);

  homeUsers = listToAttrs (map (user: {
    name = user.name;
    value = {
      home.stateVersion = args.stateVersion;
      home.username = user.name;
      home.homeDirectory = "/home/${user.name}";
      home.packages = userPackages user;

      programs.git = {
        enable = true;
        settings = {
          user = {
            name = user.git.name;
            email = user.git.email;
          };
        } // (user.git.settings or {});
      };
    };
  }) principals);
in {
  boot = {
    loader = {
      grub = {
        enable = interface.boot.loader.manager == "grub";
        device = interface.boot.loader.device;
        useOSProber = true;
        fsIdentifier = "provided";
      };

      systemd-boot = {
        enable = interface.boot.loader.manager == "systemd-boot";
        consoleMode = "max";
      };

      timeout = interface.boot.loader.timeout;
    };

    kernelPackages = pkgs.${resolved.packages.kernel};
  };

  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = darkFlavor;
    accent = darkAccent;
  };

  console.keyMap = primary.interface.keyboard.layout;

  documentation.nixos.enable = false;

  environment.systemPackages = packages;

  fonts = {
    packages = with pkgs; [
      rubik
      noto-fonts-color-emoji
      material-symbols
      maple-mono.NF-unhinted
      monaspace
      noto-fonts
    ];

    fontconfig.defaultFonts = {
      monospace = ["Maple Mono NF"];
      sansSerif = ["Monaspace Radon Frozen"];
      serif = ["Noto Serif"];
      emoji = ["Noto Color Emoji"];
    };
  };

  i18n.defaultLocale = args.localization.defaultLocale;

  networking = {
    hostName = args.name;
    hostId = args.id;
    networkmanager.enable = isFunctionality "network";
  };

  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    nixPath = [
      "nixos-config=${args.paths.roots.src}/API/nix/hosts/Preci/default.nix"
      "nixpkgs=${inputs.nixpkgs.path}"
    ];
  };

  nixpkgs = {
    config.allowUnfree = true;
    pkgs = inputs.nixpkgs;
  };

  programs = {
    bash.enable = true;
    dconf.enable = true;
    direnv = {
      enable = true;
      silent = true;
    };
    git = {
      enable = true;
      lfs.enable = true;
      prompt.enable = true;
      config = {
        user = {
          name = primary.git.name;
          email = primary.git.email;
        };
        init.defaultBranch = "main";
        safe.directory = [args.paths.roots.src];
        url."https://github.com/".insteadOf = ["gh:" "github:"];
      } // (primary.git.settings or {});
    };
    nh = {
      enable = true;
      clean.enable = true;
      flake = args.paths.roots.src;
    };
    nix-index.enable = true;
    nix-index-database = {
      enable = true;
      comma.enable = true;
    };
    starship.enable = true;
  };

  security = {
    sudo.extraRules = [
      {
        users = map (user: user.name) (builtins.filter (user: user.role == "administrator") principals);
        commands = [{
          command = "ALL";
          options = ["NOPASSWD"];
        }];
      }
    ];
    rtkit.enable = isFunctionality "audio";
  };

  services = {
    openssh.enable = true;
    tailscale.enable = isFunctionality "vpn";
    libinput.enable = isFunctionality "touchpad";
    printing.enable = true;

    pipewire = {
      enable = isFunctionality "audio";
      alsa.enable = isFunctionality "audio";
      alsa.support32Bit = isFunctionality "audio";
      pulse.enable = isFunctionality "audio";
    };

    displayManager = {
      enable = true;
      autoLogin = {
        enable = primary.autoLogin;
        user = primary.name;
      };
    };

    desktopManager.plasma6.enable = isDesktop "plasma";

    xserver = {
      enable = false;
      xkb = {
        layout = primary.interface.keyboard.layout;
        variant = primary.interface.keyboard.variant;
      };
    };
  };

  system.stateVersion = args.stateVersion;

  time.timeZone = args.localization.timeZone;

  users.users = users;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit args inputs resolved;
    };
    users = homeUsers;
  };
}
