{
  description = "Craig 'Craole' Cole";
  hashedPassword = "$y$j9T$4ttMLNfyJlF2wA65cSdqc.$G38glsCDXWcrQCEDbZZ1QIbKnMHfdnXSNnokPm0BXgD";
  localization = {
    defaultLocale = "en_GB.UTF-8";
  };

  identities = [
    {
      name = "craole-cc";
      email = "134658831+craole-cc@users.noreply.github.com";
    }
    {
      name = "Craole";
      email = "32288735+Craole@users.noreply.github.com";
    }
  ];

  packages = {
    shells = [
      "bash"
      "nushell"
      "powershell"
      "zsh"
    ];
    coding = [
      "common"
      "nix"
      "markup"
      "rust"
      "python"
      "shellscript"
      "zig"
    ];
    common = [
      "brave"
      "freetube"
      "ghostty"
      "imv"
      "qbittorrent-enhanced"
      "qimgv"
      "shortwave"
      "vscode-fhs"
    ];
    launchers = ["vicinae"];
  };

  interface = {
    desktops = [
      "plasma"
      "hyprland"
      "niri"
      # "mango"
      # "cosmic"
    ];
    fonts = let
      fira-code = {
        name = "Fira Code";
        package = "fira-code";
      };
      fira-code-nf = {
        name = "Fira Code Nerd Font";
        package = "nerd-fonts.fira-code";
      };
      ibm-plex-sans = {
        name = "IBM Plex Sans";
        package = "ibm-plex";
      };
      ibm-plex-serif = {
        name = "IBM Plex Serif";
        package = "ibm-plex";
      };
      jetbrains-mono = {
        name = "JetBrains Mono";
        package = "jetbrains-mono";
      };
      jetbrains-mono-nf = {
        name = "JetBrains Mono Nerd Font";
        package = "nerd-fonts.jetbrains-mono";
      };
      lilex = {
        name = "Lilex";
        package = "lilex";
      };
      lilex-nf = {
        name = "Lilex Nerd Font";
        package = "nerd-fonts.lilex";
      };
      maple-mono = {
        name = "Maple Mono";
        package = "maple-mono";
      };
      maple-mono-nf = {
        name = "Maple Mono NF";
        package = "maple-mono.NF-unhinted";
      };
      material-symbols-outlined = {
        name = "Material Symbols Outlined";
        package = "material-symbols";
      };
      material-symbols-rounded = {
        name = "Material Symbols Rounded";
        package = "material-symbols";
      };
      material-symbols-sharp = {
        name = "Material Symbols Sharp";
        package = "material-symbols";
      };
      monaspace-argon = {
        name = "Monaspace Argon Frozen";
        package = "monaspace";
      };
      monaspace-krypton = {
        name = "Monaspace Krypton Frozen";
        package = "monaspace";
      };
      monaspace-radon = {
        name = "Monaspace Radon Frozen";
        package = "monaspace";
      };
      noto-color-emoji = {
        name = "Noto Color Emoji";
        package = "noto-fonts-color-emoji";
      };
      noto-serif = {
        name = "Noto Serif";
        package = "noto-fonts";
      };
      noto-sans = {
        name = "Noto Sans";
        package = "noto-fonts";
      };
      overpass = {
        name = "Overpass";
        package = "overpass";
      };
      rubik = {
        name = "Rubik";
        package = "rubik";
      };
      source-code-pro = {
        name = "Source Code Pro";
        package = "source-code-pro";
      };
      source-code-pro-nf = {
        name = "Source Code Pro Nerd Font";
        package = "nerd-fonts.source-code-pro";
      };
      source-sans-pro = {
        name = "Source Sans Pro";
        package = "source-sans-pro";
      };
      source-serif-pro = {
        name = "Source Serif Pro";
        package = "source-serif-pro";
      };

      categories = {
        clock = [
          rubik
          monaspace-krypton
          source-code-pro
        ];
        emoji =
          [
            noto-color-emoji
          ]
          ++ categories.material;
        material = [
          material-symbols-sharp
          material-symbols-outlined
          material-symbols-rounded
        ];
        monospace = [
          lilex-nf
          lilex
          maple-mono-nf
          maple-mono
          jetbrains-mono-nf
          jetbrains-mono
          fira-code-nf
          fira-code
          source-code-pro-nf
          source-code-pro
        ];
        sans = [
          monaspace-radon
          monaspace-argon
          ibm-plex-sans
          source-sans-pro
          overpass
          noto-sans
        ];
        serif = [
          ibm-plex-serif
          noto-serif
          source-serif-pro
        ];
      };
    in
      categories;
    theme = {
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
}
