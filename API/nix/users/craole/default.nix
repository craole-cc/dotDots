{
  imports = [
    # ./programs/common/rust.nix #TODO: Capabilities should handle this
    # ./programs
    # ./services
  ];

  description = "Craig 'Craole' Cole";

  dms = import ./interface/dms;

  password = "$6$2o3rjHVZgXEuyZ97$PtmQa1PIOmKb6dAwZ0mZJUulAkJoCfj.qjJHgtusfVnIIsHmENcA7q8PV9I2PveOwdEdFWwMBgLu3a5HZavXC1";

  git = [
    {
      id = "craole-cc";
      name = "craole-cc";
      email = "134658831+craole-cc@users.noreply.github.com";
      root = "craole-cc";
      licence = {
        name = "Craig 'Craole' Cole";
        type = "mit";
      };
    }
    {
      id = "craole";
      name = "Craole";
      email = "32288735+Craole@users.noreply.github.com";
      root = "Craole";
      licence = {
        name = "Craig 'Craole' Cole";
        type = "mit";
      };
    }
  ];

  capabilities = {
    writing = {};
    conferencing = {};
    development = {
      languages.rust = {
        channel = "nightly";
        components = ["rust-src" "rust-analyzer" "rustfmt" "clippy"];
      };
    };
    creation = {};
    analysis = {};
    management = {};
    gaming = {};
    multimedia = {};
  };

  packages = {
    ai-agent = [
      "hermes-desktop"
      "chatgpt"
      "claude-desktop"
      "claude-code"
      "codex"
      "ollama"
    ];
    # TODO: Change to panel, here and downstream
    bar = [
      "dms"
      # "caelestia"
    ];
    browser = [
      "chromium"
      "zen-twilight"
      # "brave"
    ];
    editor = [
      "helix"
      "neovim"
    ];
    explorer = [
      "yazi"
      "doublecmd"
    ];
    shell = [
      "bash"
      "nushell"
      "powershell"
      "zsh"
    ];
    coding = [
      "common"
      "github"
      "markup"
      "nix"
      "python"
      "rust"
      "shellscript"
      "typos"
      "typst"
      "zig"
    ];
    extra = [
      "fastfetch"
      "imv"
      # TODO: Re-add OBS Studio when it is needed again.
      # "obs-studio"
      "qimgv"
      "qbittorrent-enhanced"
    ];
    media = [
      "celluloid"
      "freetube"
      "shortwave"
      "mpv"
      "playerctl"
    ];
    ide = [
      "vscode-insiders"
      "zed-editor-fhs"
      "vscode-fhs"
    ];
    launcher = [
      "vicinae"
    ];
    prompt = [
      "starship"
    ];
    terminal = [
      "ghostty"
      "foot"
      "warp-terminal"
      "kitty"
    ];
    wallpaper = [
      "variety"
    ];
  };

  paths = rec {
    pics = "home:Pictures";
    dlds = "home:Downloads";
    avatars = {
      session = pics + "/avatar.jpg";
    };
    wallpapers = "home:Pictures/Wallpapers";
  };

  interface = {
    desktops = [
      # "plasma"
      "hyprland"
      "niri"
      # "mango"
      # "cosmic"
    ];

    theme = rec {
      palettes = {
        catppuccin = {
          frappe = let
            colors = {
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
              text = "#c6d0f5";
              subtext1 = "#b5bfe2";
              subtext0 = "#a5adce";
              overlay2 = "#949cbb";
              overlay1 = "#838ba7";
              overlay0 = "#737994";
              surface2 = "#626880";
              surface1 = "#51576d";
              surface0 = "#414559";
              base = "#303446";
              mantle = "#292c3c";
              crust = "#232634";
            };
          in
            with colors; {
              name = "Catppuccin Frappé";
              variant = "dark";
              description = "Soothing pastel theme, the low-contrast dark flavor.";
              author = "Catppuccin";
              license = "MIT";
              source = "https://github.com/catppuccin/catppuccin";
              accent = mauve;
              inherit colors;
              ansi = {
                regular = {
                  inherit red green yellow blue;
                  black = surface1;
                  magenta = mauve;
                  cyan = teal;
                  white = subtext1;
                };
                bright = {
                  black = surface2;
                  white = text;
                };
              };
              background = base;
              foreground = text;
              muted = subtext0;
              surface = surface1;
            };
          latte = let
            colors = {
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
              text = "#4c4f69";
              subtext1 = "#5c5f77";
              subtext0 = "#6c6f85";
              overlay2 = "#7c7f93";
              overlay1 = "#8c8fa1";
              overlay0 = "#9ca0b0";
              surface2 = "#acb0be";
              surface1 = "#bcc0cc";
              surface0 = "#ccd0da";
              base = "#eff1f5";
              mantle = "#e6e9ef";
              crust = "#dce0e8";
            };
          in
            with colors; {
              name = "Catppuccin Latte";
              variant = "light";
              description = "Soothing pastel theme, the light flavor.";
              author = "Catppuccin";
              license = "MIT";
              source = "https://github.com/catppuccin/catppuccin";
              inherit colors;
              accent = teal;
              ansi = {
                regular = {
                  inherit red green yellow blue;
                  black = surface2;
                  magenta = pink;
                  cyan = teal;
                  white = subtext1;
                };
                bright = {
                  black = overlay0;
                  white = text;
                };
              };
              background = base;
              foreground = text;
              muted = subtext0;
              surface = surface2;
            };
        };
      };
      modes = let
        light = {
          palette = palettes.catppuccin.latte;
          icon = "buuf-nestort";
          cursor = "material-cursors";
          opacity = {
            terminal = 0.80;
            editor = 0.10;
          };
        };
        dark = {
          palette = palettes.catppuccin.frappe;
          icon = "candy-icons";
          cursor = "catppuccin-cursors";
          opacity = {
            terminal = 0.75;
            editor = 0.99;
          };
        };
        default = dark;
        autoSwitch = true;
      in {inherit dark light default autoSwitch;};
    };

    fonts = let
      mkFont = font: {
        size ? 11,
        style ? "Regular",
      }: (font // {inherit size style;});

      mkNF = {
        name,
        package,
      }: {
        name = "${name} Nerd Font";
        package = "nerd-fonts.${package}";
      };

      cinzel = let
        name = "Cinzel";
        package = "cinzel";
        serif = {inherit name package;};
        display = {
          inherit package;
          name = "${name} Decorative";
        };
      in {inherit serif display;};

      fira = let
        mk = variant: pkgSuffix: {
          name = "Fira ${variant}";
          package = "fira-${pkgSuffix}";
        };
        mono = mk "Code" "code";
        math = mk "Math" "math";
        sans = mk "Sans" "sans";
        monoNF = mkNF mono;
      in {inherit math mono monoNF sans;};

      ibm = let
        mk = variant: {
          name = "IBM Plex ${variant}";
          package = "ibm-plex";
        };
        mono = mk "Mono";
        math = mk "Math";
        sans = mk "Sans";
        serif = mk "Serif";
      in {inherit math mono sans serif;};

      # jetbrains = let
      #   name = "JetBrains Mono";
      #   package = "jetbrains-mono";
      #   mono = {inherit name package;};
      #   monoNF = mkNF {inherit name package;};
      # in {inherit mono monoNF;};

      lilex = let
        name = "Lilex";
        package = "lilex";
        mono = {inherit name package;};
        monoNF = mkNF {inherit name package;};
      in {inherit mono monoNF;};

      maple = let
        name = "Maple Mono";
        package = "maple-mono";
        mono = {inherit name package;};
        monoNF = {
          name = "${name} NF";
          package = "${package}.NF-unhinted";
        };
      in {inherit mono monoNF;};

      material = let
        mk = variant:
          mkFont {
            name = "Material Symbols ${variant}";
            package = "material-symbols";
          } {size = 12;};
      in {
        outlined = mk "Outlined";
        rounded = mk "Rounded";
        sharp = mk "Sharp";
      };

      # monaspace = let
      #   mk = name: {
      #     name = "Monaspace ${name}";
      #     package = "monaspace";
      #   };
      #   sans = mk "Neon"; #? Classic neo-grotesque sans-serif
      #   humanist = mk "Argon"; #? Humanist sans-serif with a warm feel
      #   serif = mk "Xenon"; #? Wedge-serif / slab hybrid style
      #   math = mk "Radon"; #? Cursive, expressive script-like variant
      #   square = mk "Krypton"; #? Sharp, mechanical square-sans aesthetic
      # in {inherit humanist math sans serif square;};

      orbitron = let
        name = "Orbitron";
        package = "orbitron";
        sans = {inherit name package;};
        display = {inherit name package;};
      in {inherit display sans;};

      categories = {
        display = let
          mk = font:
            mkFont font.display {
              size = 96;
              style = "Bold";
            };
        in [
          (mk cinzel)
          (mk orbitron)
        ];
        material = with material; [
          outlined
          rounded
          sharp
        ];
        math = let
          mk = font: mkFont font.math {};
        in [
          (mk fira)
        ];
        monospace = let
          mk = font: mkFont font.monoNF {};
        in [
          (mk lilex)
          (mk maple)
          (mk fira)
          # (mk jetbrains)
        ];
        sans = let
          mk = font: mkFont font.sans {};
        in [
          (mk ibm)
          (mk fira)
          (mk orbitron)
        ];
        serif = let
          mk = font: mkFont font.serif {};
        in [
          (mk ibm)
          (mk cinzel)
        ];
        square = [
          (mkFont cinzel.display {})
          (mkFont orbitron.display {})
        ];
      };
    in
      categories;

    keyboard = {
      layout = "us";
      variant = "";
      swapCapsEscape = false;
      vimKeybinds = false;
      bindings = let
        modifier = ["SUPER"];
        mkBinding = common: overrides:
          common
          // {
            modifier = overrides.modifier or (common.modifier or "");
            category = overrides.category or (common.category or "");
            description = overrides.description or (common.description or "");
            key = overrides.key or (common.key or "");
          };

        # Plain, Shift (incremental) and Super+Alt (exponential) variants of one key
        mkScale = common: key: verb: let
          desc = common.description;
        in [
          (mkBinding common {
            inherit key;
            description = "${desc}: ${verb}";
          })
          (mkBinding common {
            inherit key;
            description = "${desc}: ${verb} incrementally";
            modifier = ["Shift"];
          })
          (mkBinding common {
            inherit key;
            description = "${desc}: ${verb} exponentially";
            modifier = modifier ++ ["Alt"];
          })
        ];
      in {
        #~@ Applications
        launcher = let
          description = "Launcher";
          category = "application";
          key = "Space";
          common = {inherit category description modifier key;};
        in [
          (mkBinding common {})
          (mkBinding common {
            description = description + ": Browse clipboard history";
            modifier = modifier ++ ["Shift"];
          })
          (mkBinding common {
            description = description + ": Search files";
            modifier = modifier ++ ["Alt"];
          })
        ];

        terminalOpen = let
          description = "Open Terminal";
          key = "Return";
          category = "application";
          common = {inherit category description modifier key;};
        in [
          (mkBinding common {
            description = description + ": Primary";
          })
          (mkBinding common {
            description = description + ": Secondary";
            modifier = modifier ++ ["Shift"];
          })
        ];

        terminal = let
          description = "Terminal";
          key = "Grave";
          category = "application";
          common = {inherit category description modifier key;};
        in [
          (mkBinding common {
            description = description + ": Primary";
          })
          (mkBinding common {
            description = description + ": Secondary";
            modifier = modifier ++ ["Shift"];
          })
          (mkBinding common {
            description = description + ": Tertiary";
            modifier = modifier ++ ["Alt"];
          })
        ];

        browser = let
          description = "Browser";
          key = "B";
          category = "application";
          common = {inherit category description modifier key;};
        in [
          (mkBinding common {
            description = description + ": Primary";
          })
          (mkBinding common {
            description = description + ": Secondary";
            modifier = modifier ++ ["Shift"];
          })
          (mkBinding common {
            description = description + ": Tertiary";
            modifier = modifier ++ ["Alt"];
          })
        ];

        explorer = let
          description = "File Manager";
          key = "E";
          category = "application";
          common = {inherit category description modifier key;};
        in [
          (mkBinding common {
            description = description + ": Primary";
          })
          (mkBinding common {
            description = description + ": Secondary";
            modifier = modifier ++ ["Shift"];
          })
          (mkBinding common {
            description = description + ": Tertiary";
            modifier = modifier ++ ["Alt"];
          })
        ];

        editor = let
          description = "Code Editor";
          key = "C";
          category = "application";
          common = {inherit category description modifier key;};
        in [
          (mkBinding common {
            description = description + ": Primary";
          })
          (mkBinding common {
            description = description + ": Secondary";
            modifier = modifier ++ ["Shift"];
          })
          (mkBinding common {
            description = description + ": Tertiary";
            modifier = modifier ++ ["Alt"];
          })
        ];

        ide = let
          description = "Integrated Development Environment";
          key = "V";
          category = "application";
          common = {inherit category description modifier key;};
        in [
          (mkBinding common {
            description = description + ": Primary";
          })
          (mkBinding common {
            description = description + ": Secondary";
            modifier = modifier ++ ["Shift"];
          })
          (mkBinding common {
            description = description + ": Tertiary";
            modifier = modifier ++ ["Alt"];
          })
        ];

        agent = let
          description = "Agent";
          category = "application";
          key = "A";
          common = {inherit category description modifier key;};
        in [
          (mkBinding common {
            description = description + ": Primary";
          })
          (mkBinding common {
            description = description + ": Secondary";
            modifier = modifier ++ ["Shift"];
          })
          (mkBinding common {
            description = description + ": Tertiary";
            modifier = modifier ++ ["Alt"];
          })
        ];

        media = let
          description = "Media";
          category = "application";
          key = "M";
          common = {inherit category description modifier key;};
        in [
          (mkBinding common {description = description + ": Primary";})
          (mkBinding common {
            description = description + ": Secondary";
            modifier = modifier ++ ["Shift"];
          })
          (mkBinding common {
            description = description + ": Tertiary";
            modifier = modifier ++ ["Alt"];
          })
        ];

        #~@ System Control
        close = let
          description = "Exit";
          category = "controller";
          key = "Q";
          common = {inherit category description modifier key;};
        in [
          (mkBinding common {
            description = "${description}: Application";
            modifier = modifier ++ ["Ctrl"];
          })
          (mkBinding common {
            description = "${description}: Session";
            modifier = modifier ++ ["Ctrl" "Shift"];
          })
          (mkBinding common {
            description = "${description}: System";
            modifier = modifier ++ ["Ctrl" "Alt"];
          })
        ];

        lock = let
          description = "Lock";
          category = "controller";
          key = "L";
          common = {inherit category description modifier key;};
        in [
          (mkBinding common {description = "${description}: Screen";})
          (mkBinding common {
            description = "${description}: Session";
            modifier = modifier ++ ["Ctrl"];
          })
          (mkBinding common {
            description = "${description}: Application";
            modifier = modifier ++ ["Alt"];
          })
        ];

        window = let
          description = "Window";
          category = "controller";
          key = "F";
          common = {inherit category description modifier key;};
        in [
          (mkBinding common {description = "${description}: Fullscreen";})
          (mkBinding common {
            description = "${description}: Maximize/Restore";
            modifier = modifier ++ ["Shift"];
          })
          (mkBinding common {
            description = "${description}: Floating";
            modifier = modifier ++ ["Ctrl"];
          })
          (mkBinding common {
            description = "${description}: Maximise Column";
            modifier = modifier ++ ["Alt"];
          })
          (mkBinding common {
            description = "${description}: Switch Floating/Tiling Focus";
            modifier = modifier ++ ["Ctrl" "Shift"];
          })
          (mkBinding common {
            description = "${description}: Pin to All Workspaces";
            modifier = modifier ++ ["Ctrl" "Alt"];
          })
        ];

        workspace = let
          description = "Workspace";
          category = "controller";
          common = {inherit category description modifier;};
          mk = {
            key,
            dir,
            target,
          }: [
            (mkBinding common {
              inherit key;
              description = "${description}: Move focus ${dir}";
            })
            (mkBinding common {
              inherit key;
              description = "${description}: Move window ${dir}";
              modifier = modifier ++ ["Shift"];
            })
            (mkBinding common {
              inherit key;
              description = "${description}: Move to ${target} workspace";
              modifier = modifier ++ ["Alt"];
            })
          ];
        in
          mk {
            key = "Right";
            dir = "right";
            target = "next";
          }
          ++ mk {
            key = "Left";
            dir = "left";
            target = "previous";
          };

        #~@ Audio
        volume = let
          description = "Volume";
          category = "audio";
          common = {inherit category description;};
        in
          mkScale common "XF86AudioRaiseVolume" "Increase"
          ++ mkScale common "XF86AudioLowerVolume" "Decrease"
          ++ [
            (mkBinding common {
              description = "${description}: Mute or unmute";
              key = "XF86AudioMute";
            })
          ];

        #~@ Brightness
        brightness = let
          description = "Brightness";
          category = "display";
          common = {inherit category description;};
        in
          mkScale common "XF86MonBrightnessUp" "Increase"
          ++ mkScale common "XF86MonBrightnessDown" "Decrease";

        wallpaper = let
          description = "Wallpaper";
          category = "controller";
          common = {inherit category description;};
          altMod = modifier ++ ["Alt"];
          mod = altMod ++ ["Shift"];
        in [
          (mkBinding common {
            description = "${description}: Next";
            modifier = mod;
            key = "Period";
          })
          (mkBinding common {
            description = "${description}: Previous";
            modifier = mod;
            key = "Comma";
          })
          (mkBinding common {
            description = "${description}: Open";
            modifier = altMod;
            key = "W";
          })
          (mkBinding common {
            description = "${description}: Favourite";
            modifier = mod;
            key = "W";
          })
        ];
      };
    };
  };
}
