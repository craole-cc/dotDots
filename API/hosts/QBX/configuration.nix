{
  config,
  pkgs,
  modulesPath,
  lib,
  ...
}: let
  # ==================== USER ====================
  user = {
    name = "craole";
    description = "Craig 'Craole' Cole";

    git = {
      name = "craole-cc";
      email = "134658831+craole-cc@users.noreply.github.com";
    };

    paths = let
      home = "/home/${user.name}";
    in {
      inherit home;
      downloads = home + "/Downloads";
    };
  };

  # ==================== PATH ====================
  paths = let
    dots = "/home/${user.name}/.dots";
  in {
    inherit dots;
    base = dots + "/Configuration/hosts/QBX";
    orig = "/etc/nixos";
  };

  # ==================== HOST ====================
  host = {
    name = "QBX";
    version = "25.11";
    platform = "x86_64-linux";
  };

  # ==================== ENVIRONMENT ====================
  env = {
    variables = with paths; {
      NIXOS_ORIG = orig;
      NIXOS_BASE = base;
      DOTS = dots;
      EDITOR = "hx";
      VISUAL = "code";
    };

    aliases = {
      se = "sudo hx --config \"/home/${user.name}/.config/helix/config.toml\"";
      nxe = "$EDITOR ${paths.base}";
      nxv = "$VISUAL ${paths.base}";
      nxs = "switch";
      nxu = "switch; topgrade";
      ll = "lsd --long --git --almost-all";
      lt = "lsd --tree";
      lr = "lsd --long --git --recursive";
    };
  };
in {
  # ==================== IMPORTS ====================
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  # ==================== HARDWARE ====================
  hardware = {
    #~@ CPU
    cpu.amd.updateMicrocode = true;
    enableAllFirmware = true;
    amdgpu.initrd.enable = true;

    #~@ GPU
    graphics.enable = true;
    nvidia = {
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.production;
      forceFullCompositionPipeline = true;
      modesetting.enable = true;
      powerManagement.enable = false;
    };

    #~@ Bluetooth
    bluetooth = {
      enable = true;
      settings.General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  systemd.services = {
    "nvidia-wait-for-displays" = {
      description = "Wait for NVIDIA and AMD displays to initialize";
      wantedBy = ["display-manager.service"];
      before = ["display-manager.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.coreutils}/bin/sleep 5";
      };
    };
  };

  # ==================== BOOT ====================
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
      kernelModules = [
        "amdgpu"
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];
    };
    extraModulePackages = [];
    kernelModules = ["kvm-amd"];
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 1;
    };

    kernelParams = [
      #? For NVIDIA - Early KMS
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia.NVreg_EnableS0ixPowerManagement=1"
      "nvidia.NVreg_TemporaryFilePath=/var/tmp"
      "nvidia_drm.modeset=1"
      "nvidia_drm.fbdev=1"

      #? For AMD GPU
      "amdgpu.modeset=1"

      #? Blacklist nouveau
      "rd.driver.blacklist=nouveau"
      "modprobe.blacklist=nouveau"

      #? General stability
      "nowatchdog"
      "mitigations=off"

      #? Force probe NVIDIA outputs (card0 - the discrete GPU)
      "video=card0-DP-3:e"
      "video=card0-HDMI-A-3:e"

      #? Force probe AMD output (card1 - the motherboard/integrated)
      "video=card1-HDMI-A-2:e"
    ];

    blacklistedKernelModules = ["nouveau"];
  };

  # ==================== Filesystems ====================
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

  # ==================== NIX ====================
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  nixpkgs = {
    hostPlatform = host.platform;
    config.allowUnfree = true;
  };

  # system = {
  #   stateVersion = host.version;
  # };
  # ==================== Network ====================
  networking = {
    hostName = host.name;
    networkmanager.enable = true;
  };

  # ==================== Localization ====================
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

  # ==================== SERVICES ====================
  services = {
    #> Load nvidia driver for Xorg and Wayland
    xserver.videoDrivers = ["nvidia"];

    #~@ Network
    openssh.enable = true;

    #~@ Audio
    pipewire = {
      enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };
    pulseaudio.enable = false;

    #~@ Other services
    printing.enable = true;
    qbittorrent = {
      enable = true;
      openFirewall = true;
    };
  };

  # ==================== SECURITY ====================
  security = {
    rtkit.enable = true;
    sudo = {
      execWheelOnly = true;
      extraRules = [
        {
          users = [user.name];
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

  # ==================== FONTS ====================
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      maple-mono.NF
      monaspace
    ];
    fontconfig = {
      enable = true;
      hinting = {
        enable = true;
        style = "slight";
      };
      antialias = true;
      subpixel.rgba = "rgb";
      defaultFonts = {
        emoji = ["Noto Color Emoji"];
        monospace = [
          "Maple Mono NF"
          "Monaspace Radon"
        ];
        serif = ["Noto Serif"];
        sansSerif = ["Noto Sans"];
      };
    };
  };

  # ==================== SYSTEM PROGRAMS ====================
  programs = {
    git = {
      enable = true;
      lfs.enable = true;
      prompt.enable = true;
    };

    direnv = {
      enable = true;
      silent = true;
    };

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

  # ==================== USERS ====================
  users.users."${user.name}" = {
    inherit (user) description;
    isNormalUser = true;
    extraGroups = ["networkmanager" "wheel"];
  };

  # ==================== HOME MANAGER ====================
  home-manager.users = {
    "${user.name}" = {
      home = {
        # stateVersion = host.version;
        packages = with pkgs;
          [
            microsoft-edge
            qbittorrent-enhanced
            inkscape
            warp-terminal
          ]
          ++ [
            gImageReader
          ];
      };

      #~@ User programs configuration
      programs = {
        bat.enable = true;
        btop.enable = true;
        fastfetch.enable = true;

        #~@ Terminal
        foot = {
          enable = true;
          server.enable = true;
          settings = {
            main = {
              font = "monospace:size=16";
              dpi-aware = "yes";
              pad = "8x8";
            };
            mouse.hide-when-typing = "yes";
            scrollback.lines = 100000;
            key-bindings = {
              clipboard-copy = "Control+Shift+c XF86Copy";
              clipboard-paste = "Control+Shift+v XF86Paste";
              scrollback-up-page = "Shift+Page_Up";
              scrollback-down-page = "Shift+Page_Down";
              scrollback-up-line = "Control+Shift+Up";
              scrollback-down-line = "Control+Shift+Down";
              font-increase = "Control+plus Control+equal";
              font-decrease = "Control+minus";
              font-reset = "Control+0";
              search-start = "Control+Shift+f";
            };
            colors.alpha = 0.97;
            cursor = {
              style = "beam";
              blink = "yes";
            };
          };
        };

        #~@ Browser
        zen-browser = {
          enable = true;
          profiles.default = {
            bookmarks = {
              force = true;
              settings = [
                {
                  name = "For Nix";
                  toolbar = true;
                  bookmarks = [
                    {
                      name = "homepage";
                      url = "https://nixos.org/";
                    }
                    {
                      name = "wiki";
                      tags = ["wiki" "nix"];
                      url = "https://wiki.nixos.org/";
                    }
                  ];
                }
              ];
            };

            search = {
              default = "google";
              privateDefault = "brave";
              engines = {
                bing = {
                  name = "Bing";
                  urls = [{template = "https://www.bing.com/search?q={searchTerms}";}];
                  metaData.alias = "@mb";
                };
                brave = {
                  name = "Brave";
                  urls = [{template = "https://search.brave.com/search?q={searchTerms}";}];
                  definedAliases = ["b" "@b"];
                };
                github = {
                  name = "GitHub";
                  urls = [{template = "https://github.com/search?q={searchTerms}";}];
                  definedAliases = ["gh" "@gh"];
                };
                google.metaData.alias = "@g";
                google-images = {
                  name = "Google Images";
                  urls = [
                    {
                      template = "https://www.google.com/search";
                      params = [
                        {
                          name = "tbm";
                          value = "isch";
                        }
                        {
                          name = "q";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];
                  definedAliases = ["gi" "@gimg"];
                };
                home-manager-options = {
                  name = "Home Manager Options";
                  iconMapObj."16" = "https://nix-community.github.io/nixos-facter-modules/latest/assets/images/logo.png";
                  urls = [
                    {
                      template = "https://home-manager-options.extranix.com/";
                      params = [
                        {
                          name = "release";
                          value = "master";
                        }
                        {
                          name = "query";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];
                  definedAliases = ["hm" "@hm"];
                };
                nix-packages = {
                  name = "NixOS Packages";
                  urls = [
                    {
                      template = "https://search.nixos.org/packages";
                      params = [
                        {
                          name = "channel";
                          value = "unstable";
                        }
                        {
                          name = "query";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];
                  definedAliases = ["np" "@p"];
                };
                nixos-options = {
                  name = "NixOS Options";
                  urls = [
                    {
                      template = "https://search.nixos.org/";
                      params = [
                        {
                          name = "channel";
                          value = "unstable";
                        }
                        {
                          name = "query";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];
                  definedAliases = ["no" "@o"];
                };
                nixos-wiki = {
                  name = "NixOS Wiki";
                  urls = [{template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";}];
                  iconMapObj."16" = "https://wiki.nixos.org/favicon.ico";
                  definedAliases = ["nw" "@nw"];
                };
                noogle = {
                  name = "Noogle Dev";
                  urls = [
                    {
                      template = "https://noogle.dev/q";
                      params = [
                        {
                          name = "term";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];
                  definedAliases = ["@l" "nl"];
                };
                perplexity = {
                  name = "Perplexity";
                  urls = [
                    {
                      template = "https://www.perplexity.ai/search";
                      params = [
                        {
                          name = "q";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];
                  definedAliases = ["@px" "px"];
                };
                wikipedia = {
                  name = "Wiktionary";
                  urls = [
                    {
                      template = "https://en.wiktionary.org/wiki/Special:Search";
                      params = [
                        {
                          name = "search";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];
                  definedAliases = ["@wp"];
                };
                wiktionary = {
                  name = "Wiktionary";
                  urls = [
                    {template = "https://en.wiktionary.org/w/index.php?search={searchTerms}";}
                    {
                      template = "https://en.wiktionary.org/wiki/%s";
                      params = [
                        {
                          name = "search_query";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];
                  definedAliases = ["@dict" "@wd"];
                };
                youtube = {
                  name = "YouTube";
                  urls = [
                    {
                      template = "https://www.youtube.com/results";
                      params = [
                        {
                          name = "search_query";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];
                  definedAliases = ["@yt"];
                };
                youglish = {
                  name = "YouGlish";
                  urls = [{template = "https://youglish.com/pronounce/{searchTerms}/english";}];
                  definedAliases = ["@yg"];
                };
              };
              order = [
                "google"
                "perplexity"
                "google-images"
                "nix-packages"
                "nixos-options"
                "home-manager-options"
                "bing"
                "brave"
                "nixos-wiki"
                "github"
                "wiktionary"
                "wikipedia"
                "youtube"
                "youglish"
              ];
            };

            settings = {
              #? Common preferences
              "browser.profiles.enabled" = true;
              "browser.profiles.default" = "default";

              #? Privacy & tracking
              "privacy.trackingprotection.enabled" = true;
              "privacy.resistFingerprinting" = false;
              "privacy.donottrackheader.enabled" = true;

              #? URL bar / search
              "browser.urlbar.suggest.searches" = false;
              "browser.urlbar.suggest.history" = true;
              "browser.urlbar.suggest.bookmark" = true;
              "browser.urlbar.suggest.openpage" = true;

              #? Tabs & windows
              "toolkit.tabbox.switchByScrolling" = true;
              "browser.tabs.loadInBackground" = true;
              "browser.tabs.warnOnClose" = false;

              #? Media & performance
              "media.videocontrols.picture-in-picture.enabled" = true;
              "media.autoplay.default" = 0;
              "gfx.webrender.all" = true;

              #? Scrolling & input
              "general.smoothScroll" = true;
              "mousewheel.default.delta_multiplier_y" = 100;

              #? Downloads
              "browser.download.useDownloadDir" = true;
              "browser.download.folderList" = 1;

              #? Zen workspaces
              "zen.workspaces.continue-where-left-off" = true;
              "zen.workspaces.natural-scroll" = true;
              "zen.workspaces.swipe-actions" = true;

              #? Zen view / compact mode
              "zen.view.compact.hide-tabbar" = true;
              "zen.view.compact.hide-toolbar" = true;
              "zen.view.compact.animate-sidebar" = false;

              #? Zen welcome & onboarding
              "zen.welcome-screen.seen" = true;

              #? Zen URL bar
              "zen.urlbar.behavior" = "float";

              #? Zen theme & appearance
              "zen.theme.accent-color" = "#6366f1";
              "zen.theme.gradient" = true;
              "zen.theme.gradient.show-custom-colors" = false;
              "zen.view.gray-out-inactive-windows" = true;
              "zen.watermark.enabled" = true;

              #? Zen tabs
              "zen.tabs.rename-tabs" = true;
              "zen.tabs.dim-pending" = true;
              "zen.ctrlTab.show-pending-tabs" = true;

              #? Zen media & controls
              "zen.mediacontrols.enabled" = true;
              "zen.mediacontrols.show-on-hover" = true;

              #? Zen glance / search
              "zen.glance.enable-contextmenu-search" = true;
              "zen.glance.show-bookmarks" = true;
              "zen.glance.show-history" = true;

              #? Zen tab unloader (memory)
              "zen.tab-unloader.enabled" = true;
              "zen.tab-unloader.delay" = 300;
              "zen.tab-unloader.excluded-urls" = "https://meet.google.com,https://app.slack.com";

              #? Zen experimental / hidden
              "zen.view.experimental-rounded-view" = false;
              "zen.theme.content-element-separation" = 8;
            };
          };

          policies = {
            AutofillAddressEnabled = true;
            AutofillCreditCardEnabled = false;
            DefaultDownloadDirectory = user.paths.downloads;
            DisableAppUpdate = true;
            DisableFeedbackCommands = true;
            DisableFirefoxStudies = true;
            DisablePocket = true;
            DisableTelemetry = true;
            DontCheckDefaultBrowser = true;
            OfferToSaveLogins = false;
            PictureInPicture = true;
            EnableTrackingProtection = {
              Value = true;
              Locked = true;
              Cryptomining = true;
              Fingerprinting = true;
            };
            SanitizeOnShutdown = {
              FormData = true;
              Cache = true;
            };
          };
        };

        #~@ Version control
        git = {
          enable = true;
          lfs.enable = true;
          settings = {
            user = {inherit (user.git) name email;};
            core = {
              whitespace = "trailing-space,space-before-tab";
            };
            init.defaultBranch = "main";
            url."https://github.com/".insteadOf = ["gh:" "github:"];
          };
        };

        gitui.enable = true;
        gh.enable = true;

        jujutsu = {
          enable = true;
          settings.user = {inherit (user.git) name email;};
        };

        delta = {
          enable = true;
          enableGitIntegration = true;
          enableJujutsuIntegration = true;
        };

        #~@ Search tools
        ripgrep = {
          enable = true;
          arguments = [
            "--max-columns-preview"
            "--colors=line:style:bold"
          ];
        };

        ripgrep-all.enable = true;

        fd = {
          enable = true;
          extraOptions = ["--absolute-path"];
          ignores = [".git/" "archives" "tmp" "temp" "*.bak"];
        };

        #~@ System maintenance
        topgrade = {
          enable = true;
          settings = {
            misc = {
              assume_yes = true;
              disable = ["nix"];
              set_title = false;
              cleanup = true;
            };
            commands = {
              "Run garbage collection on Nix store" = "nix-collect-garbage";
            };
          };
        };

        #~@ Media Utilities
        mpv = {
          enable = true;
          package = with pkgs;
          with mpv-unwrapped;
            wrapper {
              mpv = override {
                ffmpeg = ffmpeg-full;
              };
            };
          defaultProfiles = ["gpu-hq"];
          config = {
            profile = "gpu-hq";
            force-window = true;
            ytdl-format = "bestvideo+bestaudio";
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

        #~@ Shell Enhancements
        starship.enable = true;

        #~@ Editor
        helix = {
          enable = true;
          languages.language = [
            {
              name = "nix";
              language-servers = ["nixd" "nil"];
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
              language-servers = ["rust-analyzer"];
              auto-format = true;
            }
            {
              name = "python";
              formatter.command = "ruff";
              auto-format = true;
            }
            {
              name = "sql";
              formatter = {
                command = "sqlformat";
                args = ["--reindent" "--indent_width" "2" "--keywords" "upper" "--identifiers" "lower" "-"];
              };
            }
            {
              name = "toml";
              formatter = {
                command = "taplo";
                args = ["format" "-"];
              };
              auto-format = true;
            }
            {
              name = "json";
              formatter = {
                command = "deno";
                args = ["fmt" "-" "--ext" "json"];
              };
              auto-format = true;
            }
            {
              name = "markdown";
              formatter = {
                command = "deno";
                args = ["fmt" "-" "--ext" "md"];
              };
              auto-format = true;
            }
            {
              name = "typescript";
              formatter = {
                command = "deno";
                args = ["fmt" "-" "--ext" "ts"];
              };
              auto-format = true;
            }
            {
              name = "tsx";
              formatter = {
                command = "deno";
                args = ["fmt" "-" "--ext" "tsx"];
              };
              auto-format = true;
            }
            {
              name = "javascript";
              formatter = {
                command = "deno";
                args = ["fmt" "-" "--ext" "js"];
              };
              auto-format = true;
            }
            {
              name = "jsx";
              formatter = {
                command = "deno";
                args = ["fmt" "-" "--ext" "jsx"];
              };
              auto-format = true;
            }
          ];
          settings = {
            editor.cursor-shape = {
              normal = "block";
              insert = "bar";
              select = "underline";
            };
            keys = {
              normal = {
                space.space = "file_picker_in_current_directory";
                "C-]" = "indent";
                C-s = ":write";
                C-S-esc = "extend_line";
                A-j = ["extend_to_line_bounds" "delete_selection" "paste_after"];
                A-k = ["extend_to_line_bounds" "delete_selection" "move_line_up" "paste_before"];
                ret = ["open_below" "normal_mode"];
                g.u = ":lsp-restart";
                esc = ["collapse_selection" "keep_primary_selection"];
                A-e = ["collapse_selection" "keep_primary_selection"];
                A-f = ["collapse_selection" "keep_primary_selection" ":format"];
                A-w = ["collapse_selection" "keep_primary_selection" ":format" ":write"];
                A-q = ":quit";
              };
              select = {
                A-e = ["collapse_selection" "keep_primary_selection" "normal_mode"];
                A-w = ["collapse_selection" "keep_primary_selection" "normal_mode" ":format" ":write"];
                A-q = ["normal_mode" ":quit"];
              };
              insert = {
                A-space = "normal_mode";
                A-e = "normal_mode";
                A-w = ["normal_mode" ":format" ":write"];
                A-q = ["normal_mode" ":quit"];
              };
            };
          };
        };

        #~@ Integrated Development Environment
        vscode = {
          enable = true;
          package = pkgs.vscode-fhs;
        };

        #~@ File Manager
        yazi.enable = true;
      };

      #~@ XDG MIME associations
      xdg.mimeApps = let
        types = [
          "application/x-extension-shtml"
          "application/x-extension-xhtml"
          "application/x-extension-html"
          "application/x-extension-xht"
          "application/x-extension-htm"
          "x-scheme-handler/unknown"
          "x-scheme-handler/mailto"
          "x-scheme-handler/chrome"
          "x-scheme-handler/about"
          "x-scheme-handler/https"
          "x-scheme-handler/http"
          "application/xhtml+xml"
          "application/json"
          "text/plain"
          "text/html"
        ];
        associations = lib.attrsets.listToAttrs (map (app: {
            name = app;
            value = "zen.desktop";
          })
          types);
      in {
        associations.added = associations;
        defaultApplications = associations;
      };
    };
  };

  # ==================== ENVIRONMENT ====================
  environment = {
    shellAliases = env.aliases;
    sessionVariables =
      env.variables
      // {
        #~@ Wayland configuration
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
      }
      # // {
      #   # Override the Wayland variables with X11
      #   QT_QPA_PLATFORM = "xcb";
      #   SDL_VIDEODRIVER = "x11";
      #   XDG_SESSION_TYPE = "x11";
      # }
      // {};

    systemPackages = with pkgs; [
      #~@ Development
      helix
      nil
      nixd
      nixfmt
      alejandra
      rust-script
      rustfmt
      gcc

      #~@ Tools
      gitui
      lm_sensors
      toybox
      lshw
      lsd
      mesa-demos
      cowsay

      #~@ Custom script
      (pkgs.writeShellScriptBin "switch" ''
        set -euo pipefail

        if [ -d "${paths.base}" ]; then
          if [ -w "${paths.base}" ]; then
            gitui --directory "${paths.base}"
          else
            printf \
              "Config base %s is not writable as %s; fix permissions instead of using sudo.\n" \
              "${paths.base}" "$(whoami)"
            exit 1
          fi
        else
          printf "Invalid config base: %s\n" "${paths.base}"
          exit 1
        fi

        printf "🔍 Dry-run + trace on %s...\n" "${paths.base}"
        if sudo nixos-rebuild dry-run --show-trace; then
          printf "✅ Dry-run passed! Switching...\n"
          sudo nixos-rebuild switch
          printf "🎉 Switch complete + auto-backup triggered\n"
        else
          printf "❌ Dry-run failed - aborting\n"
          exit 1
        fi
      '')

      (pkgs.writeShellScriptBin "wait-for-displays" ''
        set -euo pipefail

        max_attempts=10
        attempt=0

        while [ $attempt -lt $max_attempts ]; do
          # Check if all expected displays are detected
          if [ -e /sys/class/drm/card0-DP-3 ] && \
            [ -e /sys/class/drm/card0-HDMI-A-3 ] && \
            [ -e /sys/class/drm/card1-HDMI-A-2 ]; then
            printf "All displays detected\n"
            exit 0
          fi

          printf "Waiting for displays... attempt %s\n" "$attempt"
          sleep 0.5
          attempt=$((attempt + 1))
        done

        printf "Not all displays detected, continuing anyway\n"
        exit 0
      '')
    ];
  };

  # ==================== POST-ACTIVATION ====================
  # system.activationScripts.postActivation.text = ''
  #   set -euo pipefail
  #   NIXOS_BASE=${paths.base}
  #   NIXOS_ORIG=${paths.orig}

  #   [ -d "$NIXOS_ORIG" ] && rm -rf "$NIXOS_ORIG"
  #   mkdir -p "$NIXOS_ORIG"
  #   cp -R "$NIXOS_BASE"/. "$NIXOS_ORIG"/
  #   printf "✓ NixOS backup refreshed: %s → %s\n" "$NIXOS_BASE" "$NIXOS_ORIG"
  # '';
}
