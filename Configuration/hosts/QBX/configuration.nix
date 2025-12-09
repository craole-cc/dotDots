{
  inputs ? null,
  pkgs,
  modulesPath,
  ...
}:
let
  alpha =
    let
      username = "craole";
      home = "/home/${username}";
      dots = home + "/.dots";
      host = dots + "/Configuration/hosts/QBX";
      description = "Craig 'Craole' Cole";
      git = {
        name = "craole-cc";
        email = "134658831+craole-cc@users.noreply.github.com";
      };
    in
    {
      inherit
        dots
        home
        username
        host
        description
        git
        ;
    };

  getGitHub =
    {
      owner,
      repo,
      rev,
      sha256,
    }:
    builtins.fetchTarball {
      url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
      inherit sha256;
    };

  resolvedInputs =
    if inputs != null then
      inputs
    else
      {
        nixosCore = getGitHub {
          owner = "NixOS";
          repo = "nixpkgs";
          rev = "f61125a668a320878494449750330ca58b78c557";
          sha256 = "sha256-BmPWzogsG2GsXZtlT+MTcAWeDK5hkbGRZTeZNW42fwA=";
        };

        nixosHome = getGitHub {
          owner = "nix-community";
          repo = "home-manager";
          rev = "e5b1f87841810fc24772bf4389f9793702000c9b";
          sha256 = "sha256-BVVyAodLcAD8KOtR3yCStBHSE0WAH/xQWH9f0qsxbmk=";
        };
      };

  stateVersion = "25.11";
  hwModules = modulesPath + "/installer/scan/not-detected.nix";
  homeModules = import "${resolvedInputs.nixosHome}/nixos";

  confDir = "/etc/nixos";
  conf = confDir + "/configuration.nix";
in
with alpha;
{
  nix = {
    nixPath = [
      "nixpkgs=${resolvedInputs.nixosCore}"
      "nixos-config=${conf}"
    ];
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  nixpkgs = {
    hostPlatform = "x86_64-linux";
    config.allowUnfree = true;
  };

  imports = [
    hwModules
    homeModules
  ];

  hardware = {
    cpu.amd.updateMicrocode = true;

    enableAllFirmware = true;
    amdgpu.initrd.enable = true;

    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;

      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        amdgpuBusId = "PCI:12:0:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };

    graphics.enable = true;

    bluetooth = {
      enable = true;
      settings.General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
    };
    extraModulePackages = [ ];
    kernelModules = [ "kvm-amd" ];
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 1;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/1f5ca117-cd68-439b-8414-b3b39bc28d75";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/C6C0-2B64";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  networking = {
    hostName = "qbx";
    networkmanager.enable = true;
  };

  location = {
    longitude = "18.015";
    latitude = "77.49";
    provider = "manual";
  };

  time = {
    timeZone = "America/Jamaica";
    hardwareClockInLocalTime = true;
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  system = {
    inherit stateVersion;
    copySystemConfiguration = inputs == null;
  };

  services = {
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;

    openssh.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    printing.enable = true;
    pulseaudio.enable = false;

    qbittorrent = {
      enable = true;
      openFirewall = true;
    };
  };

  security = {
    rtkit.enable = true;
    sudo = {
      execWheelOnly = true;
      extraRules = [
        {
          users = [ username ];
          commands = [
            {
              command = "ALL";
              options = [
                "SETENV"
                "NOPASSWD"
              ];
            }
          ];
        }
      ];
    };
  };

  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    obs-studio = {
      enable = true;
      enableVirtualCamera = true;
    };

    xwayland.enable = true;
  };

  users.users."${username}" = {
    inherit description;
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  home-manager = {
    backupFileExtension = "backup";
    overwriteBackup = true;
    useGlobalPkgs = true;
    useUserPackages = true;
    # extraSpecialArgs = {};
    # sharedModules = [];
    users."${username}" = {
      fonts.fontconfig = {
        enable = true;
        hinting = "slight";
        antialiasing = true;
        subpixelRendering = "rgb";
        defaultFonts = {
          emoji = [ "Noto Color Emoji" ];
          monospace = [
            "Maple Mono NF"
            "Monaspace Radon"
          ];
          serif = [ "Noto Serif" ];
          sansSerif = [ "Noto Sans" ];
        };
      };

      home = {
        inherit stateVersion;
        packages = with pkgs; [
          maple-mono.NF
          monaspace
          microsoft-edge
          warp-terminal
        ];
        sessionVariables = {
        };
      };

      programs = {
        bat.enable = true;
        btop.enable = true;
        fastfetch.enable = true;
        foot = {
          enable = true;
          server.enable = true;
          settings = {
            main = {
              font = "monospace:size=14";
              dpi-aware = "yes";
              pad = "8x8"; # Padding around terminal content
            };

            mouse = {
              hide-when-typing = "yes";
            };

            scrollback = {
              lines = 10000;
            };

            key-bindings = {
              # Clipboard
              clipboard-copy = "Control+Shift+c XF86Copy";
              clipboard-paste = "Control+Shift+v XF86Paste";

              # Scrollback
              scrollback-up-page = "Shift+Page_Up";
              scrollback-down-page = "Shift+Page_Down";
              scrollback-up-line = "Control+Shift+Up";
              scrollback-down-line = "Control+Shift+Down";

              # Font size
              font-increase = "Control+plus Control+equal";
              font-decrease = "Control+minus";
              font-reset = "Control+0";

              # Search
              search-start = "Control+Shift+f";
            };

            colors = {
              alpha = 0.95; # Slight transparency (1.0 = opaque)
            };

            cursor = {
              style = "beam"; # Options: block, underline, beam
              blink = "yes";
            };
          };
        };

        firefox = {
          enable = true;
        };

        git = {
          enable = true;
          lfs.enable = true;
          settings = {
            user = { inherit (git) name email; };
            core = {
              whitespace = "trailing-space,space-before-tab";
              safeDirectory = [ "/etc/nixos" ];
            };
            init = {
              defaultBranch = "main";
            };
            url = {
              "https://github.com/" = {
                insteadOf = [
                  "gh:"
                  "github:"
                ];
              };
            };
          };
        };

        gitui.enable = true;

        gh = {
          enable = true;
        };

        jujutsu = {
          enable = true;
          settings.user = { inherit (git) name email; };
        };

        delta = {
          enable = true;
          enableGitIntegration = true;
          enableJujutsuIntegration = true;
        };

        ripgrep = {
          enable = true;
          arguments = [
            "--max-columns-preview"
            "--colors=line:style:bold"
          ];
        };
        ripgrep-all = {
          enable = true;
        };

        fd = {
          enable = true;
          extraOptions = [
            # "--no-ignore"
            "--absolute-path"
          ];
          ignores = [
            ".git/"
            "archives"
            "tmp"
            "temp"
            "*.bak"
          ];
        };

        topgrade = {
          enable = true;
          settings = {
            misc = {
              assume_yes = true;
              disable = [
                "flutter"
                "node"
              ];
              set_title = false;
              cleanup = true;
            };
            commands = {
              "Run garbage collection on Nix store" = "nix-collect-garbage";
            };
          };
        };

        mpv = {
          enable = true;
          defaultProfiles = [ "gpu-hq" ];
          config = {
            profile = "gpu-hq";
            force-window = true;
            ytdl-format = "bestvideo+bestaudio";
            # cache-default = 4000000;
          };
        };

        freetube = {
          enable = true;
          settings = {
            allowDashAv1Formats = true;
            checkForUpdates = false;
            defaultQuality = "1080";
            baseTheme = "catppuccinMocha";
          };
        };

        # oh-my-posh={
        #   enable=true;
        #   enableBashIntegration = true;
        #   enableNushellIntegration = true;
        # };

        starship = {
          enable = true;
        };

        helix = {
          enable = true;
          languages.language = [
            {
              name = "nix";
              language-servers = [ "nixd" ];
              formatter.command = "nixfmt";
              auto-format = true;
            }
            {
              name = "bash";
              indent = {
                tab-width = 2;
                unit = "	";
              };
              formatter = {
                command = "shfmt";
                arguments = "--posix --apply-ignore --case-indent --space-redirects --write";
              };
              auto-format = true;
            }
            {
              name = "rust";
              language-servers = [ "rust-analyzer" ];
              auto-format = true;
            }
            {
              name = "ruby";
              language-servers = [
                "rubocop"
                "solargraph"
              ];
              formatter = {
                command = "bundle";
                args = [
                  "exec"
                  "stree"
                  "format"
                ];

                #   command = "rubocop";
                #   args = [
                #     "--stdin"
                #     "foo.rb"
                #     "-a"
                #     "--stderr"
                #     "--fail-level"
                #     "fatal"
                #   ];
                #   timeout = 3;
              };
              auto-format = true;
            }
            {
              name = "python";
              formatter = {
                command = "ruff";
                args = [
                  # "-"
                  # "-q"
                ];
              };
              auto-format = true;
            }
            {
              name = "sql";
              formatter = {
                command = "sqlformat";
                args = [
                  "--reindent"
                  "--indent_width"
                  "2"
                  "--keywords"
                  "upper"
                  "--identifiers"
                  "lower"
                  "-"
                ];
              };
            }
            {
              name = "toml";
              formatter = {
                command = "taplo";
                args = [
                  "format"
                  "-"
                ];
              };
              auto-format = true;
            }
            {
              name = "json";
              formatter = {
                command = "deno";
                args = [
                  "fmt"
                  "-"
                  "--ext"
                  "json"
                ];
              };
              auto-format = true;
            }
            {
              name = "markdown";
              formatter = {
                command = "deno";
                args = [
                  "fmt"
                  "-"
                  "--ext"
                  "md"
                ];
              };
              auto-format = true;
            }
            {
              name = "typescript";
              formatter = {
                command = "deno";
                args = [
                  "fmt"
                  "-"
                  "--ext"
                  "ts"
                ];
              };
              auto-format = true;
            }
            {
              name = "tsx";
              formatter = {
                command = "deno";
                args = [
                  "fmt"
                  "-"
                  "--ext"
                  "tsx"
                ];
              };
              auto-format = true;
            }
            {
              name = "javascript";
              formatter = {
                command = "deno";
                args = [
                  "fmt"
                  "-"
                  "--ext"
                  "js"
                ];
              };
              auto-format = true;
            }
            {
              name = "jsx";
              formatter = {
                command = "deno";
                args = [
                  "fmt"
                  "-"
                  "--ext"
                  "jsx"
                ];
              };
              auto-format = true;
            }
          ];
          settings = {
            editor = {
              cursor-shape = {
                normal = "block";
                insert = "bar";
                select = "underline";
              };
            };

            keys = {
              normal = {
                space = {
                  space = "file_picker_in_current_directory";
                };
                "C-]" = "indent";
                C-s = ":write";
                C-S-esc = "extend_line";
                # C-S-o = ":config-open";
                # C-S-r = ":config-reload";
                # a = "move_char_left";
                # w = "move_line_up";
                A-j = [
                  "extend_to_line_bounds"
                  "delete_selection"
                  "paste_after"
                ];
                A-k = [
                  "extend_to_line_bounds"
                  "delete_selection"
                  "move_line_up"
                  "paste_before"
                ];
                ret = [
                  "open_below"
                  "normal_mode"
                ];
                g.u = ":lsp-restart";
                esc = [
                  "collapse_selection"
                  "keep_primary_selection"
                ];
                A-e = [
                  "collapse_selection"
                  "keep_primary_selection"
                ];
                A-w = [
                  "collapse_selection"
                  "keep_primary_selection"
                  ":write"
                ];
                A-q = ":quit";
              };

              select = {
                A-e = [
                  "collapse_selection"
                  "keep_primary_selection"
                  "normal_mode"
                ];
                A-w = [
                  "collapse_selection"
                  "keep_primary_selection"
                  "normal_mode"
                  ":write"
                ];
                A-q = [
                  "normal_mode"
                  ":quit"
                ];
              };

              insert = {
                A-space = "normal_mode";
                A-e = "normal_mode";
                A-w = [
                  "normal_mode"
                  ":write"
                ];
                A-q = [
                  "normal_mode"
                  ":quit"
                ];
              };
            };
          };
        };

        vscode = {
          enable = true;
          package = pkgs.vscode-fhs;
        };
      };
    };
  };

  environment = {
    sessionVariables = {
      EDITOR = "hx";
      VISUAL = "code";

      #? For Clutter/GTK apps
      CLUTTER_BACKEND = "wayland";

      #? For GTK apps
      GDK_BACKEND = "wayland";

      #? Required for Java UI apps on Wayland
      _JAVA_AWT_WM_NONREPARENTING = "1";

      #? Enable Firefox native Wayland backend
      MOZ_ENABLE_WAYLAND = "1";

      #? Force Chromium/Electron apps to use Wayland
      NIXOS_OZONE_WL = "1";

      #? Qt apps use Wayland
      QT_QPA_PLATFORM = "wayland";

      #? Disable client-side decorations for Qt apps
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

      #? Auto scale for HiDPI displays
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";

      #? SDL2 apps Wayland backend
      SDL_VIDEODRIVER = "wayland";

      #? Allow software rendering fallback on Nvidia/VM
      WLR_RENDERER_ALLOW_SOFTWARE = "1";

      #? Disable hardware cursors on Nvidia/VM
      WLR_NO_HARDWARE_CURSORS = "1";

      #? Indicate Wayland session to apps
      XDG_SESSION_TYPE = "wayland";
    };

    shellAliases = {
      sx = "sudo hx --config \"${home}/.config/helix/config.toml\"";
      nxup = "switch; topgrade";
    };

    systemPackages = with pkgs; [
      helix
      nil
      nixd
      nixfmt
      alejandra
      direnv
      rust-script
      gcc
      ripgrep
      toybox
      lsd
      mesa-demos

      (pkgs.writeShellScriptBin "nx" ''
        set -e

        USER_CONFIG="${home}/.config/helix"
        ROOT_TEMP="/tmp/root-helix-$(date +%s)"

        # Copy complete config (languages.toml + config.toml + runtime)
        printf "📝 Copying Helix config to root...\n"
        sudo mkdir -p "$ROOT_TEMP"
        sudo cp -r "$USER_CONFIG"/* "$ROOT_TEMP/"

        # Launch hx with root's temp config
        printf "✨ Launching sudo hx...\n"
        sudo hx --config "$ROOT_TEMP/config.toml" /etc/nixos/configuration.nix

        # Cleanup
        sudo rm -rf "$ROOT_TEMP"
        printf "🧹 Cleaned up temp config\n"
      '')

      (pkgs.writeShellScriptBin "switch" ''
        set -e

        sudo gitui --directory ${confDir}

        printf "🔍 Dry-run + trace...\n"
        if sudo nixos-rebuild dry-run --show-trace; then
          printf "✅ Dry-run passed! Switching...\n"
          sudo nixos-rebuild switch
          printf "🎉 Switch complete + auto-backup triggered\n"
        else
          printf "❌ Dry-run failed - aborting\n"
          exit 1
        fi
      '')
    ];
  };

  system.activationScripts.postActivation.text = ''
    # Backup configs after successful activation
    CORE_CFG="/etc/nixos"
    HOST_CFG="/home/craole/.dots/Configuration/hosts/QBX"
    mkdir -p "$HOST_CFG"
    cp -v "$CORE_CFG/configuration.nix" "$HOST_CFG/"
    cp -v "$CORE_CFG/flake.nix" "$HOST_CFG/" 2>/dev/null || true
    cp -v "$CORE_CFG/flake.lock" "$HOST_CFG/" 2>/dev/null || true
    printf "✓ NixOS config backed up → %s" "$HOST_CFG"
  '';
}
