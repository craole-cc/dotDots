{ config, pkgs, ... }:
let
  mod = "craole";
  inherit (config.system) stateVersion;
in
{
  users.users.${mod} = {
    isNormalUser = true;
    description = "Craole";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
  home-manager.users.${mod} = {
    fonts.fontconfig = {
      enable = true;
      defaultFonts = rec {
        emoji = [
          "vscodeIcons"
          "Noto Color Emoji"
        ];
        monospace = [
          "Operator Mono Lig Medium"
          "Operator Mono Lig"
          "Cascadia Code PL"
          "JetBrainsMono Nerd Font"
        ] ++ emoji;
        sansSerif = [
          "Lexend"
        ] ++ emoji;
        serif = [
          "Noto Serif"
        ] ++ emoji;
      };
    };
    home = {
      inherit stateVersion;
      enableNixpkgsReleaseCheck = false;
      packages =
        let
          fontsMono = pkgs.stdenv.mkDerivation {
            pname = "Awesome-Fonts";
            version = "1.0";

            src = pkgs.fetchFromGitHub {
              owner = "rng70";
              repo = "Awesome-Fonts";
              rev = "3733f56e431608878d6cbbf2d70d8bf36ab2c226";
              sha256 = "0m41gdgp06l5ymwvy0jkz6qfilcz3czx416ywkq76z844y5xahd0";
            };

            installPhase = ''
              mkdir -p $out/share/fonts/opentype
              find $src -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp {} $out/share/fonts/opentype/ \;
            '';
          };
        in
        with pkgs;
        [
          #| Apps
          brave
          whatsapp-for-linux
          warp-terminal
          via
          vscode-fhs
          qbittorrent
          inkscape-with-extensions
          darktable
          ansel

          #| Fonts
          fontsMono
          lexend
          material-design-icons
          material-icons
          noto-fonts-emoji
        ]
        ++ (with nerd-fonts; [
          fantasque-sans-mono
          fira-code
          hack
          jetbrains-mono
          monaspace
          monoid
          victor-mono
          zed-mono
        ]);

      sessionVariables = {
        EDITOR = "hx";
        VISUAL = "code";
        BROWSER = "brave";
        PAGER = "bat --paging=always";
        MANPAGER = "bat --paging=always --plain";
      };
      shellAliases = {
        h = "history";
        la = "eza --group-directories-first --git --almost-all  --smart-group --absolute";
        ll = "la --long";
      };
    };
    programs = {
      bash = {
        enable = true;
        # initExtra = ''[ -f "$DOTS_RC" ] && . "$DOTS_RC"'';
        historyControl = [
          "erasedups"
          "ignoredups"
          "ignorespace"
          "ignoreboth"
        ];
      };
      btop = {
        enable = true;
        settings = {
          color_theme = "nord";
          theme_background = false;
        };
      };
      eza = {
        enable = true;
        #TODO: None of these are working
        git = true;
        icons = "auto";
        extraOptions = [
          "--group-directories-first"
          "--color-scale"
        ];
      };
      git = {
        enable = true;
        userName = "Craole";
        userEmail = "32288735+Craole@users.noreply.github.com";
      };
      helix = {
        enable = true;
        languages = {
          # https://github-wiki-see.page/m/helix-editor/helix/wiki/External-formatter-configuration
          languages = [
            #| Nix
            {
              name = "nix";
              language-servers = [
                "nixd"
                "nil"
              ];
              formatter.command = "nixfmt";
              auto-format = true;
            }

            #| Shell
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

            #| Rust
            {
              name = "rust";
              language-servers = [ "rust-analyzer" ];
              auto-format = true;
            }

            #| Ruby
            {
              name = "ruby";
              language-servers = [
                "rubocop"
                "solargraph"
              ];
              config = {
                solargraph = {
                  diagnostics = true;
                  formatting = false;
                };
              };
              formatter = {
                command = "bundle";
                args = [
                  "exec"
                  "rubocop"
                  "--stdin"
                  "foo.rb"
                  "-a"
                  "--stderr"
                  "--fail-level"
                  "fatal"
                ];
              };

              # formatter = {
              #   command = "bundle";
              #   args = [
              #     "exec"
              #     "stree"
              #     "format"
              #   ];

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
              # };
              auto-format = true;
            }

            #| Python
            {
              name = "python";
              formatter = {
                command = "ruff";
                args = [
                  "format"
                  "--line-length"
                  "88"
                  "-"
                ];
              };

              # formatter = {
              #   command = "black";
              #   args = [
              #     "-"
              #     "-q"
              #   ];
              # };
              auto-format = true;
            }

            #| SQL
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

            #| Toml
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

            #| Json
            {
              name = "json";
              formatter = {

                command = "prettier";
                args = [
                  "--parser"
                  "json"
                ];

                # command = "deno";
                # args = [
                #   "fmt"
                #   "-"
                #   "--ext"
                #   "json"
                # ];
              };
              auto-format = true;
            }

            #| Markdown
            {
              name = "markdown";
              formatter = {

                command = "prettier";
                args = [
                  "--parser"
                  "markdown"
                ];

                # command = "deno";
                # args = [
                #   "fmt"
                #   "-"
                #   "--ext"
                #   "md"
                # ];

              };
              auto-format = true;
            }

            #| TypeScript
            {
              name = "typescript";
              formatter = {

                command = "prettier";
                args = [
                  "--parser"
                  "typescript"
                ];

                # command = "deno";
                # args = [
                #   "fmt"
                #   "-"
                #   "--ext"
                #   "ts"
                # ];
              };
              auto-format = true;
            }
            {
              name = "tsx";
              formatter = {

                command = "prettier";
                args = [
                  "--parser"
                  "tsx"
                ];
                # command = "deno";
                # args = [
                #   "fmt"
                #   "-"
                #   "--ext"
                #   "tsx"
                # ];
              };
              auto-format = true;
            }

            #| JavaScript
            {
              name = "javascript";
              formatter = {

                command = "prettier";
                args = [
                  "--parser"
                  "javascript"
                ];

                # command = "deno";
                # args = [
                #   "fmt"
                #   "-"
                #   "--ext"
                #   "js"
                # ];
              };
              auto-format = true;
            }
            {
              name = "jsx";
              formatter = {

                command = "prettier";
                args = [
                  "--parser"
                  "jsx"
                ];

                # command = "deno";
                # args = [
                #   "fmt"
                #   "-"
                #   "--ext"
                #   "jsx"
                # ];
              };
              auto-format = true;
            }
          ];
        };
        settings = {
          editor = {
            auto-save = true;
            auto-format = true;
            bufferline = "never";
            cursorline = true;
            cursor-shape = {
              insert = "bar";
              normal = "block";
              select = "underline";
            };
            statusline = {
              left = [
                "mode"
                "spinner"
                "spacer"
                "file-modification-indicator"
              ];
              center = [ "file-name" ];
              right = [
                "diagnostics"
                "version-control"
                "selections"
                "position"
                "file-encoding"
              ];
              mode = {
                normal = "NORMAL";
                insert = "INSERT";
                select = "SELECT";
              };
              separator = "│";
            };
            idle-timeout = 50;
            line-number = "relative";
            lsp = {
              auto-signature-help = true;
              display-inlay-hints = true;
              display-messages = true;
              display-signature-help-docs = true;
              snippets = true;
            };
            indent-guides = {
              render = true;
              character = "╎"; # "▏", "╎", "┆", "┊", "⸽"
              skip-levels = 1;
              rainbow-option = "normal";
            };
            mouse = false;
            soft-wrap = {
              enable = true;
              wrap-at-text-width = true;
            };
            text-width = 120;
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
          theme = "gruvbox-dark";
        };
      };
      ripgrep = {
        enable = true;
        arguments = [
          "--max-columns-preview"
          "--colors=line:style:bold"
        ];
      };
      # vscode = {
      #   enable = true;
      #   package = pkgs.vscode-fhs;
      #   enableUpdateCheck = false;
      #   mutableExtensionsDir = true;
      # };
      skim = {
        enable = true;
        defaultCommand = "rg --files --hidden";
        changeDirWidgetOptions = [
          "--preview 'eza --icons --git --color always -T -L 3 {} | head -200'"
          "--exact"
        ];
      };
      starship = {
        enable = true;
      };
      obs-studio = {
        enable = true;
      };
      freetube = {
        enable = true;
      };
      mpv = {
        enable = true;
      };
      atuin = {
        enable = true;
      };
      plasma = {
        enable = true;

        #
        # Some high-level settings:
        #
        workspace = {
          clickItemTo = "open"; # If you liked the click-to-open default from plasma 5
          lookAndFeel = "org.kde.breezedark.desktop";
          cursor = {
            theme = "Bibata-Modern-Ice";
            size = 32;
          };
          iconTheme = "Papirus-Dark";
          wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Patak/contents/images/1080x1920.png";
        };

        hotkeys.commands."launch-konsole" = {
          name = "Launch Konsole";
          key = "Meta+Alt+K";
          command = "konsole";
        };

        fonts = {
          general = {
            family = "JetBrains Mono";
            pointSize = 12;
          };
        };

        desktop.widgets = [
          {
            plasmusicToolbar = {
              position = {
                horizontal = 51;
                vertical = 100;
              };
              size = {
                width = 250;
                height = 250;
              };
            };
          }
        ];

        panels = [
          # Windows-like panel at the bottom
          {
            location = "bottom";
            widgets = [
              # We can configure the widgets by adding the name and config
              # attributes. For example to add the the kickoff widget and set the
              # icon to "nix-snowflake-white" use the below configuration. This will
              # add the "icon" key to the "General" group for the widget in
              # ~/.config/plasma-org.kde.plasma.desktop-appletsrc.
              {
                name = "org.kde.plasma.kickoff";
                config = {
                  General = {
                    icon = "nix-snowflake-white";
                    alphaSort = true;
                  };
                };
              }
              # Or you can configure the widgets by adding the widget-specific options for it.
              # See modules/widgets for supported widgets and options for these widgets.
              # For example:
              {
                kickoff = {
                  sortAlphabetically = true;
                  icon = "nix-snowflake-white";
                };
              }
              # Adding configuration to the widgets can also for example be used to
              # pin apps to the task-manager, which this example illustrates by
              # pinning dolphin and konsole to the task-manager by default with widget-specific options.
              {
                iconTasks = {
                  launchers = [
                    "applications:org.kde.dolphin.desktop"
                    "applications:org.kde.konsole.desktop"
                  ];
                };
              }
              # Or you can do it manually, for example:
              {
                name = "org.kde.plasma.icontasks";
                config = {
                  General = {
                    launchers = [
                      "applications:org.kde.dolphin.desktop"
                      "applications:org.kde.konsole.desktop"
                    ];
                  };
                };
              }
              # If no configuration is needed, specifying only the name of the
              # widget will add them with the default configuration.
              "org.kde.plasma.marginsseparator"
              # If you need configuration for your widget, instead of specifying the
              # the keys and values directly using the config attribute as shown
              # above, plasma-manager also provides some higher-level interfaces for
              # configuring the widgets. See modules/widgets for supported widgets
              # and options for these widgets. The widgets below shows two examples
              # of usage, one where we add a digital clock, setting 12h time and
              # first day of the week to Sunday and another adding a systray with
              # some modifications in which entries to show.
              {
                digitalClock = {
                  calendar.firstDayOfWeek = "sunday";
                  time.format = "12h";
                };
              }
              {
                systemTray.items = {
                  # We explicitly show bluetooth and battery
                  shown = [
                    "org.kde.plasma.battery"
                    "org.kde.plasma.bluetooth"
                  ];
                  # And explicitly hide networkmanagement and volume
                  hidden = [
                    "org.kde.plasma.networkmanagement"
                    "org.kde.plasma.volume"
                  ];
                };
              }
            ];
            hiding = "autohide";
          }
          # Application name, Global menu and Song information and playback controls at the top
          {
            location = "top";
            height = 26;
            widgets = [
              {
                applicationTitleBar = {
                  behavior = {
                    activeTaskSource = "activeTask";
                  };
                  layout = {
                    elements = [ "windowTitle" ];
                    horizontalAlignment = "left";
                    showDisabledElements = "deactivated";
                    verticalAlignment = "center";
                  };
                  overrideForMaximized.enable = false;
                  titleReplacements = [
                    {
                      type = "regexp";
                      originalTitle = "^Brave Web Browser$";
                      newTitle = "Brave";
                    }
                    {
                      type = "regexp";
                      originalTitle = ''\\bDolphin\\b'';
                      newTitle = "File manager";
                    }
                  ];
                  windowTitle = {
                    font = {
                      bold = false;
                      fit = "fixedSize";
                      size = 12;
                    };
                    hideEmptyTitle = true;
                    margins = {
                      bottom = 0;
                      left = 10;
                      right = 5;
                      top = 0;
                    };
                    source = "appName";
                  };
                };
              }
              "org.kde.plasma.appmenu"
              "org.kde.plasma.panelspacer"
              {
                plasmusicToolbar = {
                  panelIcon = {
                    albumCover = {
                      useAsIcon = false;
                      radius = 8;
                    };
                    icon = "view-media-track";
                  };
                  playbackSource = "auto";
                  musicControls.showPlaybackControls = true;
                  songText = {
                    displayInSeparateLines = true;
                    maximumWidth = 640;
                    scrolling = {
                      behavior = "alwaysScroll";
                      speed = 3;
                    };
                  };
                };
              }
            ];
          }
        ];

        window-rules = [
          {
            description = "Dolphin";
            match = {
              window-class = {
                value = "dolphin";
                type = "substring";
              };
              window-types = [ "normal" ];
            };
            apply = {
              noborder = {
                value = true;
                apply = "force";
              };
              # `apply` defaults to "apply-initially"
              maximizehoriz = true;
              maximizevert = true;
            };
          }
        ];

        powerdevil = {
          AC = {
            powerButtonAction = "lockScreen";
            autoSuspend = {
              action = "shutDown";
              idleTimeout = 1000;
            };
            turnOffDisplay = {
              idleTimeout = 1000;
              idleTimeoutWhenLocked = "immediately";
            };
          };
          battery = {
            powerButtonAction = "sleep";
            whenSleepingEnter = "standbyThenHibernate";
          };
          lowBattery = {
            whenLaptopLidClosed = "hibernate";
          };
        };

        kwin = {
          edgeBarrier = 0; # Disables the edge-barriers introduced in plasma 6.1
          cornerBarrier = false;

          scripts.polonium.enable = true;
        };

        kscreenlocker = {
          lockOnResume = true;
          timeout = 10;
        };

        #
        # Some mid-level settings:
        #
        shortcuts = {
          ksmserver = {
            "Lock Session" = [
              "Screensaver"
              "Meta+Ctrl+Alt+L"
            ];
          };

          kwin = {
            "Expose" = "Meta+,";
            "Switch Window Down" = "Meta+J";
            "Switch Window Left" = "Meta+H";
            "Switch Window Right" = "Meta+L";
            "Switch Window Up" = "Meta+K";
          };
        };

        #
        # Some low-level settings:
        #
        configFile = {
          baloofilerc."Basic Settings"."Indexing-Enabled" = false;
          kwinrc."org.kde.kdecoration2".ButtonsOnLeft = "SF";
          kwinrc.Desktops.Number = {
            value = 8;
            # Forces kde to not change this value (even through the settings app).
            immutable = true;
          };
          kscreenlockerrc = {
            Greeter.WallpaperPlugin = "org.kde.potd";
            # To use nested groups use / as a separator. In the below example,
            # Provider will be added to [Greeter][Wallpaper][org.kde.potd][General].
            "Greeter/Wallpaper/org.kde.potd/General".Provider = "bing";
          };
        };
      };
    };
  };
}
