{
  lix ? args.lix or import ./lib.nix {},
  src ? args.host or import ./.,
  ...
} @ args: let

    host = {
      functionalities = [];
      localization = {
        latitude = 18.015;
        longitude = -77.49;
        city = "Mandeville, Jamaica";
        timeZone = "America/Jamaica";
        defaultLocale = "en_US.UTF-8";
      };
      interface = {
        boot = {
          loader = {
            manager = "systemd-boot";
            device = "nodev";
            timeout = 5;
          };
        };
        desktops = [];
        fonts = {
          clock = [
            {
              name = "Monaspace Krypton Frozen";
              package = "monaspace";
            }
          ];
          emoji = [
            {
              name = "Noto Color Emoji";
              package = "noto-fonts-color-emoji";
            }
          ];
          material = [
            {
              name = "Material Symbols Outlined";
              package = "material-symbols";
            }
          ];
          monospace = [
            {
              name = "Maple Mono";
              package = "maple-mono";
            }
          ];
          sans = [
            {
              name = "IBM Plex Sans";
              package = "ibm-plex";
            }
          ];
          serif = [
            {
              name = "Noto Serif";
              package = "noto-fonts";
            }
          ];
        };
        themes = {
          autoSwitch = true;
          dark = {
            flavor = "frappe";
            accent = "mauve";
            icons = "candy-icons";
            dark = "material-cursors";
          };
          light = {
            flavor = "latte";
            accent = "teal";
            icons = "buuf-nestort";
            dark = "material-cursors";
          };
          palettes = {
            frappe = {
              #~@ Metadata
              name = "Catppuccin Frappé";
              slug = "catppuccin-frappe";
              description = "Soft dark theme with muted tones";
              variant = "dark";
              icon = "icons/catppuccin-frappe.png";

              #~@ Core Base Colors
              base = "#303446";
              mantle = "#292c3c";
              crust = "#232634";

              #~@ Text & Subtext
              text = "#c6d0f5";
              subtext1 = "#b5bfe2";
              subtext0 = "#a5adce";

              #~@ UI Surfaces & Overlays
              surface0 = "#414559";
              surface1 = "#51576d";
              surface2 = "#626880";
              overlay0 = "#737994";
              overlay1 = "#838ba7";
              overlay2 = "#949cbb";

              #~@ Accents
              rosewater = "#f2d5cf";
              flamingo = "#eebebe";
              pink = "#f4b8e4";
              mauve = "#ca9ee6";
              red = "#e78284";
              maroon = "#ea999c";
              peach = "#ef9f76";
              yellow = "#e5c890";
              green = "#a6d189";
              teal = "#81c8be";
              sky = "#99d1db";
              sapphire = "#85c1dc";
              blue = "#8caaee";
              lavender = "#babbf1";
            };

            latte = {
              #~@ Metadata
              name = "Catppuccin Latte";
              slug = "catppuccin-latte";
              description = "Cozy light theme with color-rich accents";
              variant = "light";
              icon = "icons/catppuccin-latte.png";

              #~@ Core Base Colors
              base = "#eff1f5";
              mantle = "#e6e9ef";
              crust = "#dce0e8";

              #~@ Text & Subtext
              text = "#4c4f69";
              subtext1 = "#5c5f77";
              subtext0 = "#6c6f85";

              #~@ UI Surfaces & Overlays
              surface0 = "#ccd0da";
              surface1 = "#bcc0cc";
              surface2 = "#acb0be";
              overlay0 = "#9ca0b0";
              overlay1 = "#8c8fa1";
              overlay2 = "#7c7f93";

              #~@ Accents
              rosewater = "#dc8a78";
              flamingo = "#dd7878";
              pink = "#ea76cb";
              mauve = "#8839ef";
              red = "#d20f39";
              maroon = "#e64553";
              peach = "#fe640b";
              yellow = "#df8e1d";
              green = "#40a02b";
              teal = "#179299";
              sky = "#04a5e5";
              sapphire = "#209fb5";
              blue = "#1e66f5";
              lavender = "#7287fd";
            };
          };
          polarity = "dark"; #? Base for single mode applications
        };
        keyboard = {
          layout = "us";
          variant = "";
          swapCapsEscape = false;
          vimKeybinds = false;
          bindings = let
            modifier = ["SUPER"];
          in {
            #~@ Applications
            launcher = let
              description = "Launcher";
              category = "application";
              key = "Space";
              shared = {inherit category description modifier key;};
            in [
              shared
              (
                shared
                // {
                  description = description + ": Browse clipboard history";
                  modifier = modifier ++ ["Shift"];
                }
              )
              (
                shared
                // {
                  description = description + ": Search files";
                  modifier = modifier ++ ["Alt"];
                }
              )
            ];

            terminal = let
              description = "Terminal";
              key = "Grave";
              category = "application";
              shared = {inherit category description modifier key;};
            in [
              (
                shared
                // {description = description + ": Scrathpad";}
              )
              (
                shared
                // {
                  description = description + ": Primary";
                  modifier = modifier ++ ["Shift"];
                }
              )
              (
                shared
                // {
                  description = description + ": Secondary";
                  modifier = modifier ++ ["Alt"];
                }
              )
            ];

            browser = let
              description = "Browser";
              key = "B";
              category = "application";
              shared = {inherit category description modifier key;};
            in [
              (
                shared
                // {description = description + ": Scrathpad";}
              )
              (
                shared
                // {
                  description = description + ": Primary";
                  modifier = modifier ++ ["Shift"];
                }
              )
              (
                shared
                // {
                  description = description + ": Secondary";
                  modifier = modifier ++ ["Alt"];
                }
              )
            ];

            explorer = let
              description = "File Manager";
              key = "E";
              category = "application";
              shared = {inherit category description modifier key;};
            in [
              (shared // {description = description + ": Scrathpad";})
              (
                shared
                // {
                  description = description + ": Primary";
                  modifier = modifier ++ ["Shift"];
                }
              )
              (
                shared
                // {
                  description = description + ": Secondary";
                  modifier = modifier ++ ["Alt"];
                }
              )
            ];

            editor = let
              description = "Editor";
              key = "C";
              category = "application";
              shared = {inherit category description modifier key;};
            in [
              (shared // {description = description + ": Scrathpad";})
              (
                shared
                // {
                  description = description + ": Primary";
                  modifier = modifier ++ ["Shift"];
                }
              )
              (
                shared
                // {
                  description = description + ": Secondary";
                  modifier = modifier ++ ["Alt"];
                }
              )
            ];

            agent = let
              description = "Agent";
              category = "application";
              key = "A";
              shared = {inherit category description modifier key;};
            in [
              (shared // {description = description + ": Scrathpad";})
              (
                shared
                // {
                  description = description + ": Primary";
                  modifier = modifier ++ ["Shift"];
                }
              )
              (
                shared
                // {
                  description = description + ": Secondary";
                  modifier = modifier ++ ["Alt"];
                }
              )
            ];

            #~@ System Control
            close = let
              description = "Exit";
              category = "controller";
              key = "Q";
              shared = {inherit category description modifier key;};
            in [
              (shared // {description = description + ": Application";})
              {
                inherit key;
                description = description + ": Session";
                modifier = modifier ++ ["Shift"];
              }
              {
                inherit key;
                description = description + ": System";
                modifier = modifier ++ ["Ctrl"];
              }
            ];

            lock = let
              description = "Lock";
              category = "controller";
              key = "L";
              shared = {inherit category description modifier key;};
            in [
              (shared // {description = description + ": Screen";})
              {
                inherit key;
                description = description + "Session";
                modifier = modifier ++ ["Ctrl"];
              }
              {
                inherit key;
                description = description + ": Application";
                modifier = modifier ++ ["Alt"];
              }
            ];

            window = let
              description = "Window";
              category = "controller";
              key = "F";
              shared = {inherit category description modifier key;};
            in [
              (shared // {description = description + ": Fullscreen";})
              (
                shared
                // {
                  description = description + ": Floating";
                  modifier = modifier ++ ["Shift"];
                }
              )
            ];

            workspaceNext = let
              description = "Workspace";
              category = "controller";
              key = "Right";
              shared = {inherit category description modifier key;};
            in [
              (
                shared
                // {description = description + ": Move focus right";}
              )
              (
                shared
                // {
                  description = description + ": Move window right";
                  modifier = modifier ++ ["Shift"];
                }
              )
              (
                shared
                // {
                  description = description + ": Move to next workspace";
                  modifier = modifier ++ ["Alt"];
                }
              )
            ];

            workspacePrev = let
              description = "Workspace";
              category = "controller";
              key = "Left";
              shared = {inherit category description modifier key;};
            in [
              (
                shared
                // {description = description + ": Move focus left";}
              )
              (
                shared
                // {
                  description = description + ": Move window left";
                  modifier = modifier ++ ["Shift"];
                }
              )
              (
                shared
                // {
                  description = description + ": Move to previous workspace";
                  modifier = modifier ++ ["Alt"];
                }
              )
            ];

            #~@ Audio
            volumeUp = let
              description = "Volume";
              category = "audio";
              key = "XF86AudioRaiseVolume";
              shared = {inherit category description key;};
            in [
              (
                shared
                // {description = description + ": Increase";}
              )
              (
                shared
                // {
                  description = description + ": Increase incrementally";
                  modifier = ["Shift"];
                }
              )
              (
                shared
                // {
                  description = description + ": Increase exponentially";
                  modifier = modifier ++ ["Alt"];
                }
              )
            ];

            volumeDown = let
              description = "Volume";
              category = "audio";
              key = "XF86AudioLowerVolume";
              shared = {inherit category description key;};
            in [
              (
                shared
                // {description = description + ": Decrease";}
              )
              (
                shared
                // {
                  description = description + ": Decrease incrementally";
                  modifier = ["Shift"];
                }
              )
              (
                shared
                // {
                  description = description + ": Decrease exponentially";
                  modifier = modifier ++ ["Alt"];
                }
              )
            ];

            volumeMute = let
              description = "Volume";
              category = "audio";
              key = "XF86AudioMute";
              shared = {inherit category description key;};
            in [
              (
                shared
                // {description = description + ": Mute or unmute";}
              )
            ];

            #~@ Brightness
            brightnessUp = let
              description = "Brightness";
              category = "display";
              key = "XF86MonBrightnessUp";
              shared = {inherit category description key;};
            in [
              (
                shared
                // {description = description + ": Increase";}
              )
              (
                shared
                // {
                  description = description + ": Increase incrementally";
                  modifier = ["Shift"];
                }
              )
              (
                shared
                // {
                  description = description + ": Increase exponentially";
                  modifier = modifier ++ ["Alt"];
                }
              )
            ];

            brightnessDown = let
              description = "Brightness";
              category = "display";
              key = "XF86MonBrightnessDown";
              shared = {inherit category description key;};
            in [
              (
                shared
                // {description = description + ": Decrease";}
              )
              (
                shared
                // {
                  description = description + ": Decrease incrementally";
                  modifier = ["Shift"];
                }
              )
              (
                shared
                // {
                  description = description + ": Decrease exponentially";
                  modifier = modifier ++ ["Alt"];
                }
              )
            ];
          };
        };
      };
      paths = rec {
        roots = {
          src = null; #? Must be set by the host
          run = "/etc/nixos";
        };
        dots = roots.src;
      };
      specs = {};
      packages = rec {
        kernel = "linuxPackages_latest";
        shells = ["bash"];
        coding = [];
        launchers = [
          "vicinae" #? Application Launcher
        ];
        common =
          [
            "helix" #? Editor
            "brave" #? Browser
            "freetube" #? YouTube Player
            "ghostty" #? Terminal Emulator
            "qimgv" #? Image Viewer
            "mpv" #? Media Player
          ]
          ++ launchers;
      };
      principals = [];
    };
    user = {
      applications = {};
      localization = {};
      identities = [];
      interface = {};
    };


  # src;
  #     users = let
  #       normalize = user: let
  #         home = "/home/${user.name}";
  #         shells = user.applications.shells or ["bash"];
  #         apps =
  #           (user.applications.common or [])
  #           ++ (user.applications.launchers or []);
  #         coding = user.applications.coding or [];
  #         role = user.role or "normal";
  #         isNormalUser = role != "service";
  #       in
  #         user
  #         // {
  #           inherit role shells apps coding isNormalUser;
  #           isSystemUser = !isNormalUser;
  #           paths =
  #             user.paths or {
  #               inherit home;
  #               inherit (paths.roots) src;
  #               cfg = {
  #                 source = "${paths.roots.src}/Configuration";
  #                 target = "${home}/.config";
  #               };
  #             };
  #         }
  #         // optionalAttrs isNormalUser {
  #           defaultLocale = user.defaultLocale or
  #           args.localization.defaultLocale;
  #           keyboard =
  #             recursiveUpdate {
  #               layout = "us";
  #               variant = "";
  #             }
  #             (user.keyboard or {});
  #         };
  #       normalized =
  #         mapAttrs
  #         (_: normalize) (
  #           listToAttrs (
  #             map (value: {
  #               inherit value;
  #               inherit (value) name;
  #             })
  #             (src.principals or [])
  #           )
  #         );
  #       enabled =
  #         filterAttrs
  #         (_: user: user.enable or false == true)
  #         normalized;
  #       disabled =
  #         filterAttrs
  #         (_: user: user.enable or false == false)
  #         normalized;
  #       normal =
  #         filterAttrs
  #         (_: user: user.isNormalUser)
  #         normalized;
  #       principal =
  #         normalized.${
  #           (head (
  #             filter
  #             (user: user.enable or false)
  #             (src.principals or [])
  #           )).name
  #         };
  #       core =
  #         mapAttrs
  #         (
  #           _: user:
  #             {
  #               description = user.description or user.name;
  #               inherit (user) isNormalUser isSystemUser name;
  #               extraGroups =
  #                 optionals
  #                 (user.role == "administrator")
  #                 ["networkmanager" "wheel"];
  #               shell = getAttr (head user.shells) pkgs;
  #             }
  #             // optionalAttrs (user ? password) {inherit (user) password;}
  #             // optionalAttrs (user ? uid) {inherit (user) uid;}
  #         )
  #         normalized;
  #       autoLogin = let
  #         candidates =
  #           filterAttrs
  #           (_: user: user.autoLogin or false)
  #           normalized;
  #         enable = isNotEmpty candidates;
  #       in {
  #         inherit enable;
  #         user =
  #           if enable
  #           then head (attrNames candidates)
  #           else principal.name;
  #       };
  #     in {inherit enabled disabled normal principal core autoLogin;};
  #     paths.dots = src.paths.roots.src;
  #     interface = let
  #       normalized = map toLower (args.interface.desktops or []);
  #       aliases = {
  #         plasma = ["plasma" "plasma6" "kde"];
  #         hyprland = ["hyprland" "hypr" "hype"];
  #         niri = ["niri"];
  #         gnome = ["gnome"];
  #         cosmic = ["cosmic"];
  #         i3 = ["i3"];
  #         bspwm = ["bspwm"];
  #         openbox = ["openbox"];
  #         lab = ["labwc" "lab"];
  #         mango = ["mango" "mangowc"];
  #       };
  #       protocols = let
  #         collect = list: intersectLists normalized list;
  #       in {
  #         wayland = collect [
  #           "cosmic"
  #           "gnome"
  #           "hyprland"
  #           "mango"
  #           "niri"
  #           "plasma"
  #         ];
  #         x11 = collect [
  #           "bspwm"
  #           "i3"
  #           "labwc"
  #           "openbox"
  #         ];
  #       };
  #       isRequired = desktop:
  #         isNotEmpty
  #         (intersectLists aliases.${desktop} normalized);
  #     in
  #       recursiveUpdate (args.interface or {}) {
  #         inherit protocols;
  #         boot.loader =
  #           recursiveUpdate {
  #             manager = "systemd-boot";
  #             device = "nodev";
  #             timeout = 1;
  #           }
  #           (args.interface.boot.loader or {});
  #         isBspwm = isRequired "bspwm";
  #         isCosmic = isRequired "cosmic";
  #         isGnome = isRequired "gnome";
  #         isHyprland = isRequired "hyprland";
  #         isI3 = isRequired "i3";
  #         isLab = isRequired "lab";
  #         isMango = isRequired "mango";
  #         isNiri = isRequired "niri";
  #         isOpenbox = isRequired "openbox";
  #         isPlasma = isRequired "plasma";
  #         isWayland = isNotEmpty protocols.wayland;
  #         isX11 = isNotEmpty protocols.x11;
  #         #? `desktops` is an ordered preference list on both the host
  #         #? (interface.desktops, in default.nix) and the principal
  #         #? (craole.nix). The principal's preference wins; the host list and
  #         #? "plasma" are the fallback chain if the principal is empty.
  #         defaultSession = head (principal.desktops ++ normalized ++ ["plasma"]);
  #       };
  #     aesthetics = let
  #       of = user: let
  #         theme =
  #           recursiveUpdate
  #           {
  #             autoSwitch = true;
  #             polarity = "dark";
  #             dark = {
  #               flavor = "frappe";
  #               accent = "blue";
  #             };
  #             light = {
  #               flavor = "latte";
  #               accent = "blue";
  #             };
  #             #? craole.nix nests the palette definitions under theme.palettes.*
  #             #? rather than directly under theme.*; mirror that shape so a
  #             #? principal that only overrides theme.dark/theme.light still gets
  #             #? these as the default palette source.
  #             palettes = {
  #               frappe = {
  #                 #~@ Metadata
  #                 name = "Catppuccin Frappé";
  #                 slug = "catppuccin-frappe";
  #                 description = "Soft dark theme with muted tones";
  #                 variant = "dark";
  #                 icon = "icons/catppuccin-frappe.png";
  #                 #~@ Core Base Colors
  #                 base = "#303446";
  #                 mantle = "#292c3c";
  #                 crust = "#232634";
  #                 #~@ Text & Subtext
  #                 text = "#c6d0f5";
  #                 subtext1 = "#b5bfe2";
  #                 subtext0 = "#a5adce";
  #                 #~@ UI Surfaces & Overlays
  #                 surface0 = "#414559";
  #                 surface1 = "#51576d";
  #                 surface2 = "#626880";
  #                 overlay0 = "#737994";
  #                 overlay1 = "#838ba7";
  #                 overlay2 = "#949cbb";
  #                 #~@ Accents
  #                 rosewater = "#f2d5cf";
  #                 flamingo = "#eebebe";
  #                 pink = "#f4b8e4";
  #                 mauve = "#ca9ee6";
  #                 red = "#e78284";
  #                 maroon = "#ea999c";
  #                 peach = "#ef9f76";
  #                 yellow = "#e5c890";
  #                 green = "#a6d189";
  #                 teal = "#81c8be";
  #                 sky = "#99d1db";
  #                 sapphire = "#85c1dc";
  #                 blue = "#8caaee";
  #                 lavender = "#babbf1";
  #               };
  #               latte = {
  #                 #~@ Metadata
  #                 name = "Catppuccin Latte";
  #                 slug = "catppuccin-latte";
  #                 description = "Cozy light theme with color-rich accents";
  #                 variant = "light";
  #                 icon = "icons/catppuccin-latte.png";
  #                 #~@ Core Base Colors
  #                 base = "#eff1f5";
  #                 mantle = "#e6e9ef";
  #                 crust = "#dce0e8";
  #                 #~@ Text & Subtext
  #                 text = "#4c4f69";
  #                 subtext1 = "#5c5f77";
  #                 subtext0 = "#6c6f85";
  #                 #~@ UI Surfaces & Overlays
  #                 surface0 = "#ccd0da";
  #                 surface1 = "#bcc0cc";
  #                 surface2 = "#acb0be";
  #                 overlay0 = "#9ca0b0";
  #                 overlay1 = "#8c8fa1";
  #                 overlay2 = "#7c7f93";
  #                 #~@ Accents
  #                 rosewater = "#dc8a78";
  #                 flamingo = "#dd7878";
  #                 pink = "#ea76cb";
  #                 mauve = "#8839ef";
  #                 red = "#d20f39";
  #                 maroon = "#e64553";
  #                 peach = "#fe640b";
  #                 yellow = "#df8e1d";
  #                 green = "#40a02b";
  #                 teal = "#179299";
  #                 sky = "#04a5e5";
  #                 sapphire = "#209fb5";
  #                 blue = "#1e66f5";
  #                 lavender = "#7287fd";
  #               };
  #             };
  #           }
  #           (
  #             recursiveUpdate
  #             (args.interface.theme or {})
  #             (user.theme or {})
  #           );
  #         icons =
  #           recursiveUpdate
  #           {
  #             #? craole.nix sets these per-mode under theme.dark.icons /
  #             #? theme.light.icons rather than a separate top-level `icons`
  #             #? attr; fall back to that, then to Papirus if neither is set.
  #             dark = theme.dark.icons or "Papirus-Dark";
  #             light = theme.light.icons or "Papirus-Light";
  #           }
  #           (
  #             recursiveUpdate
  #             (args.interface.icons or {})
  #             (user.icons or {})
  #           );
  #         kdeScheme = let
  #           mkName = mode: let
  #             inherit (theme.${mode}) flavor accent;
  #           in
  #             "Catppuccin"
  #             + capitalize flavor
  #             + capitalize accent;
  #         in {
  #           dark = mkName "dark";
  #           light = mkName "light";
  #         };
  #       in {
  #         inherit theme icons kdeScheme;
  #         #? The palette for the mode set in `polarity`, used for static things like boot and console
  #         active = theme.${theme.polarity};
  #       };
  #     in {
  #       inherit of;
  #       primary = of principal;
  #       users = mapAttrs (_: of) users.normal;
  #     };
  #     #? Bare `palettes` is referenced further down (vicinae themes, foot colors)
  #     #? for the principal's flavor set; keep it here rather than re-deriving
  #     #? aesthetics.primary.theme.palettes at each call site.
  #     palettes = aesthetics.primary.theme.palettes;
  #     variables = let
  #       stems = {
  #         cfg = "/Configuration";
  #         host = "/${name}";
  #         hosts = "/API/nix/hosts";
  #       };
  #       env = variables;
  #       HOST = name;
  #     in {
  #       #~@ Paths
  #       DOTS_STORE = sources.dots;
  #       DOTS_LOCAL = paths.roots.src;
  #       DOTS_BUILD = paths.roots.run;
  #       DOTS = env.DOTS_LOCAL;
  #       DOTS_HOSTS = env.DOTS_LOCAL_HOSTS;
  #       DOTS_LOCAL_HOSTS = env.DOTS_LOCAL + stems.hosts;
  #       DOTS_STORE_HOSTS = env.DOTS_STORE + stems.hosts;
  #       "DOTS_LOCAL_HOST_${HOST}" = env.DOTS_LOCAL_HOSTS + stems.host;
  #       "DOTS_STORE_HOST_${HOST}" = env.DOTS_STORE_HOSTS + stems.host;
  #       DOTS_STORE_CFG = env.DOTS_STORE + stems.cfg;
  #       DOTS_LOCAL_CFG = env.DOTS_LOCAL + stems.cfg;
  #       #~@ Inputs
  #       REV_URL_CORE = sources.revision.nixpkgs.url;
  #       REV_URL_HOME = sources.revision.home-manager.url;
  #       REV_URL_INDEX = sources.revision.nix-index.url;
  #       REV_URL_CATPPUCCIN = sources.revision.catppuccin.url;
  #       REV_URL_DOTS = sources.revision.dots.url;
  #       #~@ Metadata
  #       inherit HOST;
  #       #~@ Theme
  #       THEME_KDE_LIGHT = (aesthetics.of principal).kdeScheme.light;
  #       THEME_KDE_DARK = (aesthetics.of principal).kdeScheme.dark;
  #       THEME_GTK_LIGHT = "catppuccin-latte-blue-standard";
  #       THEME_GTK_DARK = "catppuccin-frappe-blue-standard";
  #       THEME_ICONS_LIGHT = (aesthetics.of principal).icons.light;
  #       THEME_ICONS_DARK = (aesthetics.of principal).icons.dark;
  #     };
  #     packages = let
  #       #? Per-shell packages, pulled into a user's own profile (home.packages)
  #       #? based on that user's `shells` list in default.nix — never installed
  #       #? system-wide.
  #       forShells = {
  #         bash = with pkgs; [bash];
  #         fish = with pkgs; [fish];
  #         nushell = with pkgs;
  #           [
  #             nushell
  #             nu-lint
  #             nufmt
  #           ]
  #           ++ (with pkgs.nushellPlugins; [
  #             polars
  #             gstat
  #             skim
  #             query
  #             formats
  #             desktop_notifications
  #           ]);
  #         powershell = with pkgs; [
  #           powershell
  #           powershell-editor-services
  #           (writeShellApplication {
  #             name = "pwshfmt";
  #             runtimeInputs = [powershell];
  #             text = ''
  #               export PSModulePath="${let
  #                 pname = "PSScriptAnalyzer";
  #                 version = "1.25.0";
  #               in
  #                 stdenvNoCC.mkDerivation {
  #                   inherit pname version;
  #                   src = fetchurl {
  #                     url = "https://www.powershellgallery.com/api/v2/package/${pname}/${version}";
  #                     hash = "sha256-FOY0yCjrmO+59AspGLqQ8TntXszfZjoqdHc22ZaZXWA="; #? lib.fakeHash to update
  #                   };
  #                   nativeBuildInputs = [unzip];
  #                   dontUnpack = true;
  #                   dontBuild = true;
  #                   installPhase = ''
  #                     mkdir -p "$out/share/powershell/Modules/${pname}"
  #                     unzip -q "$src" -d "$out/share/powershell/Modules/${pname}"
  #                   '';
  #                 }}/share/powershell/Modules''${PSModulePath:+:$PSModulePath}"
  #               exec pwsh \
  #                 -NoProfile \
  #                 -NonInteractive \
  #                 -File ${sources.dots + "/Libraries/powershell/Admin/pwshfmt.ps1"} \
  #                 "$@"
  #             '';
  #           })
  #         ];
  #         zsh = with pkgs; [zsh zi];
  #       };
  #       #? Per-language/tooling packages, pulled into a user's own profile
  #       #? (home.packages) based on that user's `coders` list in default.nix —
  #       #? never installed system-wide. Add new categories here as needed.
  #       forCoding = {
  #         common = with pkgs; [
  #           bat
  #           btop
  #           coreutils
  #           curl
  #           diffutils
  #           dua
  #           dust
  #           eza
  #           fastfetch
  #           fd
  #           fend
  #           figlet
  #           file
  #           findutils
  #           fzf
  #           gawk
  #           getent
  #           gh
  #           gitui
  #           gnused
  #           gum
  #           glib
  #           procs
  #           glib
  #           helix
  #           imagemagick
  #           imv
  #           jq
  #           jql
  #           lolcat
  #           lsd
  #           lshw
  #           dbus
  #           glib
  #           gnused
  #           procps
  #           systemd
  #           onefetch
  #           ouch
  #           p7zip
  #           patch
  #           pciutils
  #           pkg-config
  #           procs
  #           procps
  #           ripgrep
  #           rsync
  #           sad
  #           speedtest-go
  #           trashy
  #           treefmt
  #           udiskie
  #           usbutils
  #           uutils-coreutils-noprefix
  #           viu
  #           wget
  #           wlr-randr
  #           yazi
  #         ];
  #         markup = with pkgs;
  #           [
  #             actionlint
  #             biome
  #             rumdl
  #             stylua
  #             tombi
  #             typos
  #             typst
  #             typstyle
  #             yamlfmt
  #           ]
  #           ++ (with typstPackages; [typsy]);
  #         nix = with pkgs; [
  #           alejandra
  #           cachix
  #           lorri
  #           nil
  #           nix-diff
  #           nix-index
  #           nix-info
  #           nix-output-monitor
  #           nix-prefetch
  #           nix-prefetch-docker
  #           nix-prefetch-github
  #           nix-prefetch-scripts
  #           nixd
  #           nixfmt
  #           nvfetcher
  #           statix
  #         ];
  #         python = with pkgs; [
  #           python3Minimal
  #           ruff
  #         ];
  #         rust = with pkgs; [
  #           cargo
  #           clippy
  #           rust-analyzer
  #           rustc
  #           rustfmt
  #           leptosfmt
  #           gcc
  #         ];
  #         shellscript = with pkgs; [
  #           shellcheck
  #           shfmt
  #           (writeShellApplication {
  #             name = "shflint";
  #             runtimeInputs = [shellcheck shfmt];
  #             text = ''
  #               ${readFile (
  #                 sources.dots
  #                 + "/Libraries/posix/project/formatters/shflint"
  #               )}
  #             '';
  #           })
  #         ];
  #         zig = with pkgs; [
  #           zig
  #           ziglint
  #           zls
  #         ];
  #       };
  #       forInterface =
  #         (with pkgs; [adwaita-icon-theme])
  #         ++ optionals (with interface; isX11 || isWayland) (with pkgs; [
  #           mpvc
  #           mpv
  #           imagemagick
  #           imv
  #         ])
  #         ++ optionals interface.isWayland (with pkgs; [
  #           wl-clipboard
  #           xwayland-satellite
  #           foot
  #         ])
  #         ++ optional interface.isNiri (with pkgs; [alacritty fuzzel])
  #         ++ optional interface.isHyprland (with pkgs; [kitty])
  #         ++ optionals interface.isPlasma (with pkgs.kdePackages; [
  #           kate
  #           kconfig
  #           koi
  #           plasma-workspace
  #           sources.catppuccin-konsole
  #           yakuake
  #         ])
  #         ++ map
  #         (name: sources.icons.${name} or pkgs.${name})
  #         (unique (
  #           concatMap
  #           (elements: with elements.icons; [dark light])
  #           (attrValues aesthetics.users)
  #         ))
  #         ++ (let
  #           perUser = attrValues aesthetics.users;
  #         in [
  #           (pkgs.catppuccin-kde.override {
  #             flavour = unique (
  #               concatMap
  #               (user: with user.theme; [dark.flavor light.flavor])
  #               perUser
  #             );
  #             accents = unique (
  #               concatMap
  #               (user: with user.theme; [dark.accent light.accent])
  #               perUser
  #             );
  #           })
  #         ])
  #         ++ [
  #           (writeShellApplication {
  #             name = "theme-toggle";
  #             runtimeInputs = with pkgs; [coreutils libnotify];
  #             bashOptions = [];
  #             text = ''
  #               #> Use the DMS-generated Matugen schemes only while DMS is running;
  #               if
  #                 command -v dms >/dev/null 2>&1 &&
  #                   dms ipc call theme getMode >/dev/null 2>&1
  #               then
  #                 THEME_KDE_LIGHT="DankMatugenLight";
  #                 THEME_KDE_DARK="DankMatugenDark";
  #                 THEME_GTK_LIGHT="DankMatugenLight";
  #                 THEME_GTK_DARK="DankMatugenDark";
  #               else
  #                 THEME_KDE_LIGHT="${variables.THEME_KDE_LIGHT}";
  #                 THEME_KDE_DARK="${variables.THEME_KDE_DARK}";
  #                 THEME_GTK_LIGHT="${variables.THEME_GTK_LIGHT}";
  #                 THEME_GTK_DARK="${variables.THEME_GTK_DARK}";
  #               fi
  #               THEME_ICONS_LIGHT="${variables.THEME_ICONS_LIGHT}";
  #               THEME_ICONS_DARK="${variables.THEME_ICONS_DARK}";
  #               THEME_KDE_SCHEME_LIGHT="$THEME_KDE_LIGHT";
  #               THEME_KDE_SCHEME_DARK="$THEME_KDE_DARK";
  #               export \
  #                 THEME_KDE_SCHEME_LIGHT \
  #                 THEME_KDE_LOOKANDFEEL_LIGHT \
  #                 THEME_KDE_SCHEME_DARK \
  #                 THEME_KDE_LOOKANDFEEL_DARK \
  #                 THEME_KDE_LIGHT \
  #                 THEME_KDE_DARK \
  #                 THEME_GTK_LIGHT \
  #                 THEME_GTK_DARK \
  #                 THEME_ICONS_LIGHT \
  #                 THEME_ICONS_DARK
  #               ${readFile (
  #                 sources.dots
  #                 + "/Libraries/posix/interface/theme/theme-switch.sh"
  #               )}
  #             '';
  #           })
  #         ];
  #       forSystem = flatten (
  #         with pkgs;
  #           [
  #             coreutils
  #             curl
  #             diffutils
  #             file
  #             findutils
  #             gawk
  #             git
  #             gnused
  #             lshw
  #             patch
  #             pciutils
  #             procps
  #             rsync
  #             usbutils
  #             wget
  #           ]
  #           ++ optionals isLinux (with pkgs; [bubblewrap xsel])
  #           ++ optionals isDarwin (with pkgs; [pngpaste])
  #           ++ [
  #             (writeShellApplication {
  #               name = "nixos-switch";
  #               runtimeInputs = with pkgs; [coreutils git gum nixos-rebuild];
  #               text = with variables; ''
  #                 export DOTS="${DOTS}"
  #                 export DOTS_BUILD="${DOTS_BUILD}"
  #                 export DOTS_HOSTS="${DOTS_HOSTS}"
  #                 export HOST="${HOST}"
  #                 export REV_URL_CORE="${REV_URL_CORE}"
  #                 export REV_URL_HOME="${REV_URL_HOME}"
  #                 export REV_URL_INDEX="${REV_URL_INDEX}"
  #                 export REV_URL_CATPPUCCIN="${REV_URL_CATPPUCCIN}"
  #                 export REV_URL_DOTS="${REV_URL_DOTS}"
  #                 ${readFile (sources.dots + "/Libraries/posix/packages/manager/nix/nixos-switch.sh")}
  #               '';
  #             })
  #           ]
  #           #? One `git-profile NAME` per identity in principal.git, in list
  #           #? order (the head is also what `programs.git` applies globally).
  #           #? Only sets `--local` config, so it's scoped to the repo you're in.
  #           #? craole.nix's entries carry no directory, so this is a manual
  #           #? switch rather than an automatic `includeIf`; add a `path` to an
  #           #? entry and wire up `programs.git.includes` if you want that later.
  #           ++ optionals (isNotEmpty principal.git) (let
  #             #? `push.autoSetupRemote = true;` is nested-attrset sugar for
  #             #? `push = { autoSetupRemote = true; };`, not a flat dotted key,
  #             #? so flatten to the dotted paths `git config` actually wants.
  #             flattenSettings = prefix: attrs:
  #               concatMap (
  #                 k: let
  #                   v = attrs.${k};
  #                   path =
  #                     if prefix == ""
  #                     then k
  #                     else "${prefix}.${k}";
  #                 in
  #                   if isAttrs v
  #                   then flattenSettings path v
  #                   else [
  #                     {
  #                       inherit path;
  #                       value = v;
  #                     }
  #                   ]
  #               ) (attrNames attrs);
  #           in [
  #             (writeShellApplication {
  #               name = "git-profile";
  #               runtimeInputs = with pkgs; [git];
  #               text = ''
  #                 usage() {
  #                   cat <<'EOF'
  #                 usage: git-profile [NAME]
  #                 Set user.name/user.email (and any per-profile git config) for
  #                 the CURRENT repository only. With no argument, lists the
  #                 configured profiles in priority order (first = global default).
  #                 EOF
  #                 }
  #                 list_profiles() {
  #                   cat <<'EOF'
  #                 ${concatMapStringsSep "\n" (p: "${p.name} <${p.email}>") principal.git}
  #                 EOF
  #                 }
  #                 if [ "$#" -eq 0 ]; then
  #                   list_profiles
  #                   exit 0
  #                 fi
  #                 case "''${1:-}" in
  #                   -h | --help)
  #                     usage
  #                     exit 0
  #                     ;;
  #                 ${concatMapStringsSep "\n" (p: ''
  #                     "${p.name}")
  #                       git config user.name "${p.name}"
  #                       git config user.email "${p.email}"
  #                       ${concatMapStringsSep "\n" (
  #                       s: ''git config "${s.path}" "${toString s.value}"''
  #                     ) (flattenSettings "" (p.settings or {}))}
  #                       echo "Switched to ${p.name} <${p.email}> for $(git rev-parse --show-toplevel)"
  #                       ;;
  #                   '')
  #                   principal.git}
  #                 *)
  #                   echo "unknown profile: $1" >&2
  #                   list_profiles >&2
  #                   exit 1
  #                   ;;
  #                 esac
  #               '';
  #             })
  #           ])
  #       );
  #     in {inherit forShells forCoding forInterface forSystem;};
in {}
