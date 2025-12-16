{
  pkgs,
  lib,
  user,
  ...
}: {
  home = {
    packages = with pkgs;
      [
        microsoft-edge
        qbittorrent-enhanced
        inkscape
        warp-terminal
      ]
      ++ [gImageReader];
  };

  #~@ User programs configuration
  programs = {
    # bat.enable = true;
    # btop.enable = true;
    # fastfetch.enable = true;

    # #~@ Terminal
    # foot = {
    #   enable = true;
    #   server.enable = true;
    #   settings = {
    #     main = {
    #       font = "monospace:size=16";
    #       dpi-aware = "yes";
    #       pad = "8x8";
    #     };
    #     mouse.hide-when-typing = "yes";
    #     scrollback.lines = 100000;
    #     key-bindings = {
    #       clipboard-copy = "Control+Shift+c XF86Copy";
    #       clipboard-paste = "Control+Shift+v XF86Paste";
    #       scrollback-up-page = "Shift+Page_Up";
    #       scrollback-down-page = "Shift+Page_Down";
    #       scrollback-up-line = "Control+Shift+Up";
    #       scrollback-down-line = "Control+Shift+Down";
    #       font-increase = "Control+plus Control+equal";
    #       font-decrease = "Control+minus";
    #       font-reset = "Control+0";
    #       search-start = "Control+Shift+f";
    #     };
    #     colors.alpha = 0.97;
    #     cursor = {
    #       style = "beam";
    #       blink = "yes";
    #     };
    #   };
    # };

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
        # DefaultDownloadDirectory = user.paths.downloads;
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
    # git = {
    #   enable = true;
    #   lfs.enable = true;
    #   settings = {
    #     user = {inherit (user.git) name email;};
    #     core = {
    #       whitespace = "trailing-space,space-before-tab";
    #     };
    #     init.defaultBranch = "main";
    #     url."https://github.com/".insteadOf = ["gh:" "github:"];
    #   };
    # };

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
          # disable = ["nix"];
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
    # starship.enable = true;

    # #~@ Editor
    # helix = {
    #   enable = true;
    #   languages.language = [
    #     {
    #       name = "nix";
    #       language-servers = ["nixd" "nil"];
    #       formatter.command = "nixfmt";
    #       auto-format = true;
    #     }
    #     {
    #       name = "bash";
    #       indent = {
    #         tab-width = 2;
    #         unit = "	";
    #       };
    #       formatter = {
    #         command = "shfmt";
    #         arguments = "--posix --apply-ignore --case-indent --space-redirects --write";
    #       };
    #       auto-format = true;
    #     }
    #     {
    #       name = "rust";
    #       language-servers = ["rust-analyzer"];
    #       auto-format = true;
    #     }
    #     {
    #       name = "python";
    #       formatter.command = "ruff";
    #       auto-format = true;
    #     }
    #     {
    #       name = "sql";
    #       formatter = {
    #         command = "sqlformat";
    #         args = ["--reindent" "--indent_width" "2" "--keywords" "upper" "--identifiers" "lower" "-"];
    #       };
    #     }
    #     {
    #       name = "toml";
    #       formatter = {
    #         command = "taplo";
    #         args = ["format" "-"];
    #       };
    #       auto-format = true;
    #     }
    #     {
    #       name = "json";
    #       formatter = {
    #         command = "deno";
    #         args = ["fmt" "-" "--ext" "json"];
    #       };
    #       auto-format = true;
    #     }
    #     {
    #       name = "markdown";
    #       formatter = {
    #         command = "deno";
    #         args = ["fmt" "-" "--ext" "md"];
    #       };
    #       auto-format = true;
    #     }
    #     {
    #       name = "typescript";
    #       formatter = {
    #         command = "deno";
    #         args = ["fmt" "-" "--ext" "ts"];
    #       };
    #       auto-format = true;
    #     }
    #     {
    #       name = "tsx";
    #       formatter = {
    #         command = "deno";
    #         args = ["fmt" "-" "--ext" "tsx"];
    #       };
    #       auto-format = true;
    #     }
    #     {
    #       name = "javascript";
    #       formatter = {
    #         command = "deno";
    #         args = ["fmt" "-" "--ext" "js"];
    #       };
    #       auto-format = true;
    #     }
    #     {
    #       name = "jsx";
    #       formatter = {
    #         command = "deno";
    #         args = ["fmt" "-" "--ext" "jsx"];
    #       };
    #       auto-format = true;
    #     }
    #   ];
    #   settings = {
    #     editor.cursor-shape = {
    #       normal = "block";
    #       insert = "bar";
    #       select = "underline";
    #     };
    #     keys = {
    #       normal = {
    #         space.space = "file_picker_in_current_directory";
    #         "C-]" = "indent";
    #         C-s = ":write";
    #         C-S-esc = "extend_line";
    #         A-j = ["extend_to_line_bounds" "delete_selection" "paste_after"];
    #         A-k = ["extend_to_line_bounds" "delete_selection" "move_line_up" "paste_before"];
    #         ret = ["open_below" "normal_mode"];
    #         g.u = ":lsp-restart";
    #         esc = ["collapse_selection" "keep_primary_selection"];
    #         A-e = ["collapse_selection" "keep_primary_selection"];
    #         A-f = ["collapse_selection" "keep_primary_selection" ":format"];
    #         A-w = ["collapse_selection" "keep_primary_selection" ":format" ":write"];
    #         A-q = ":quit";
    #       };
    #       select = {
    #         A-e = ["collapse_selection" "keep_primary_selection" "normal_mode"];
    #         A-w = ["collapse_selection" "keep_primary_selection" "normal_mode" ":format" ":write"];
    #         A-q = ["normal_mode" ":quit"];
    #       };
    #       insert = {
    #         A-space = "normal_mode";
    #         A-e = "normal_mode";
    #         A-w = ["normal_mode" ":format" ":write"];
    #         A-q = ["normal_mode" ":quit"];
    #       };
    #     };
    #   };
    # };

    #~@ Integrated Development Environment
    # vscode = {
    #   enable = true;
    #   package = pkgs.vscode-fhs;
    # };

    #~@ File Manager
    # yazi.enable = true;
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
}
