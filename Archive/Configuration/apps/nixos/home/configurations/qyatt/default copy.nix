{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with types;
let
  inherit (config) dots;

  user = "craole";
  cfg = dots.users."${user}";

  inherit (config.system) stateVersion;
  inherit (dots.hosts.${dib.currentHost}) admin;
in
{
  options.dots.users."${user}" = {
    enable = mkEnableOption "Initialize the user account for {{user}}";

    isNormalUser = mkOption {
      type = bool;
      default = true;
      description = "Allow the user to login";
    };

    isAdmin = mkOption {
      type = bool;
      default = admin == user;
      description = "Is this is the system's main administrator?";
    };

    name = mkOption {
      type = passwdEntry str;
      default = user;
      apply =
        x:
        assert (
          builtins.stringLength x < 32
          || abort "Username '${x}' is longer than 31 characters which is not allowed!"
        );
        x;
      description = "The name of the user account.";
    };

    uid = mkOption {
      type = nullOr int;
      default = 1551;
      description = "The unique id number withing the range of `1000` to `59999`";
    };

    hashedPassword = mkOption {
      type = nullOr (passwdEntry str);
      default = "$y$j9T$2/KP4Wdc085m.udldFeHA0$C8K1uEH1hBwM0SHXg5l2Rnvy3jGEnq/p0MN7O7ZIXw3";
      description = "Use `mkpasswd` to generate a hash of the user's password";
    };

    description = mkOption {
      type = str;
      default = "Craig 'Craole' Cole";
      description = "User's description";
    };

    extraGroups = mkOption {
      type = listOf str;
      default = [
        "wheel"
        "networkmanager"
      ];
      description = "The user's auxiliary groups.";
    };

    variables = mkOption {
      type = attrs;
      default =
        let
          inherit (cfg)
            paths
            browser
            editor
            terminal
            ;
          inherit (paths) media downloads projects;
          inherit (media)
            music
            pictures
            wallpaper
            videos
            ;
          inherit (downloads) books research tutorials;
          inherit (videos) movies tv;
        in
        {
          PROJECTS = projects.default;
          PICTURES = pictures;
          WALLPAPER = wallpaper;
          MUSIC = music;
          DOWNLOADS = downloads.default;
          TUTORIALS = tutorials;
          BOOKS = books;
          RESEARCH = research;
          VIDEOS = videos.default;
          MOVIES = movies;
          TV = tv;
          BROWSER = browser.primary;
          EDITOR = editor.tui;
          VISUAL = editor.gui;
          TERMINAL = terminal.primary;
        };
      description = "User's environment variables";
    };

    shellAliases = mkOption {
      type = attrs;
      default = {
        gitnit = "gitini --email ${git.email} --name ${git.name}";
        cdRuby = "cd ${paths.projects.ruby}";
        cdRust = "cd ${paths.projects.rust}";
      };
      description = "User's shell aliases";
    };

    ssh = mkOption {
      type = attrs;
      default = {
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPZLZzDkJWWwfVOCiOZzZ0wkcbIyu6sSRktila4YiT5w";
        age = "age12a8xzr4zkeq0cx5qywjgxydpj6k2sqdeznqnxwjdv4puuxvyqscsgz22yg";
      };
      description = "SSH configuration";
    };

    git = {
      name = mkOption {
        type = str;
        default = "Craole";
        description = "Git username";
      };
      email = mkOption {
        type = str;
        default = "32288735+Craole@users.noreply.github.com";
        description = "Git enail";
      };
      sshKey = mkOption {
        type = str;
        default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBNIEMrsteaXwEydURdn+qCQ0JIGeqwDmlddsDc5MjQ";
        description = "Git ssh key";
      };
    };

    paths = mkOption {
      type = attrs;
      default = rec {
        config = ./. + "/${user}.nix";
        homeDirectory = "/home/${user}";
        toLink = [ ];
        media = rec {
          default = homeDirectory;
          pictures = default + "/Pictures";
          wallpaper = "${pictures}/Wallpapers";
          music = default + "/Music";
          videos = rec {
            default = homeDirectory + "/Videos";
            movies = default + "/Movies";
            tv = default + "/TV";
          };
        };
        downloads = rec {
          default = homeDirectory + "/Downloads";
          tutorials = default + "/Tutorials";
          books = default + "/Books";
          research = default + "/Dotfiles";
        };
        projects = rec {
          default = homeDirectory + "/Projects";
          ruby = default + "/Ruby";
          rust = default + "/Rust";
        };
      };
    };

    context = mkOption {
      type = listOf str;
      default = [
        "development"
        "gaming"
        "productivity"
      ];
    };

    packages = mkOption {
      description = "List of packages to install.";
      type = listOf str;
      default = [
        # | Desktop
        "hyprland"
        # "waybar"
        # "anyrun"
        "brightnessctl"

        # | Shells
        "bash"
        "nushell"

        # | Terminals
        "wezterm"
        "kitty"
        "rio"
        "foot"

        # | Development
        "vscode"
        "helix"
        # "vscodium"
        "nix"
        "shellscript"

        # | Utils
        "atuin"
        "bat"
        "eza"
        "lf"
        "starship"
        "tealdeer"
        "thefuck"
        "zoxide"

        # | Web
        "firefox"
        # "chromium"
        "brave"
        "git"
        "qbittorrent"

        # | Audio
        "beets"
        "cmus"
        "curseradio"
        "mousai"
        "mellowplayer"
        "playerctl"
        "shortwave"
        "songrec"
        "termusic"
        "subdl"

        # | Photo
        # "gimp"
        # "inkscape"
        "rawtherapee"

        # | Video
        "freetube"
        "mpv"
        # "obs-studio"
      ];
    };

    theme = {
      color = {
        mode = mkOption {
          type = enum [
            "dark"
            "light"
          ];
          # default = "dark";
          default = "light";
          description = "The color mode to use.";
        };

        scheme = {
          dark = mkOption {
            type = str;
            default = "darkGruvbox";
            description = "The dark color scheme to use.";
          };

          light = mkOption {
            type = str;
            default = "lightGruvbox";
            description = "The light color scheme to use.";
          };

          default = mkOption {
            type = str;
            default =
              if cfg.theme.color.mode == "dark" then
                cfg.theme.color.scheme.dark
              else
                cfg.theme.color.scheme.light;
            description = "The default color scheme to use.";
          };
        };
      };

      wallpaper =
        let
          inherit (cfg.paths.media) wallpaper;
        in
        {
          light = mkOption {
            type = path;
            default = wallpaper + "/04199_lonelyisland_1920x1080.jpg";
            description = "The light wallpaper to use.";
          };

          dark = mkOption {
            type = path;
            default = wallpaper + "/04114_intotheforest_1920x1080.jpg";
            description = "The dark wallpaper to use.";
          };

          default = mkOption {
            type = path;
            default =
              if cfg.theme.color.mode == "dark" then cfg.theme.wallpaper.dark else cfg.theme.wallpaper.light;
            description = "The default wallpaper to use.";
          };
        };

      icons = {
        vscode = {
          iconTheme = {
            name = mkOption {
              type = types.str;
              default = "material-icon-theme";
            };
            package = mkOption {
              type = types.package;
              default = pkgs.vscode-extensions.pkief.material-icon-theme;
            };
          };
          productIconTheme = {
            name = mkOption {
              type = types.str;
              default = "material-product-icons";
            };
            package = mkOption {
              type = types.package;
              default = pkgs.vscode-extensions.pkief.material-product-icons;
            };
          };
        };

        gtk = {
          package = mkOption {
            type = package;
            default = pkgs.catppuccin-papirus-folders;
            description = "GTK theme package.";
          };
          name = mkOption {
            type = str;
            default = "Papirus";
            description = "GTK theme name.";
          };
        };
      };

      gtk = {
        name = mkOption {
          type = str;
          default = "Bibata-Modern-Ice";
          description = "The cursor name within the package.";
        };

        package = mkOption {
          type = package;
          default = pkgs.bibata-cursors;
          description = "Package providing the cursor theme.";
        };

        size = mkOption {
          type = int;
          default = 24;
          description = "The cursor size.";
        };
      };

      fonts = {
        packages =
          let
            nerdfonts = pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; };
            awesomeFonts = fetchFromGitHub {
              owner = "rng70";
              repo = "Awesome-Fonts";
              rev = "3733f56e431608878d6cbbf2d70d8bf36ab2c226";
              sha256 = "0m41gdgp06l5ymwvy0jkz6qfilcz3czx416ywkq76z844y5xahd0";
            };
          in
          mkOption {
            type = listOf package;
            default = with pkgs; [
              awesomeFonts
              lexend
              material-design-icons
              material-icons
              nerdfonts
              noto-fonts-emoji
            ];
            description = "The font packages to use.";
          };

        monospace = mkOption {
          type = listOf str;
          default = [
            "Operator Mono Lig Medium"
            "Operator Mono Lig"
            "Cascadia Code PL"
            "JetBrainsMono Nerd Font"
            "vscodeIcons"
            "Noto Color Emoji"
          ];
          description = "The monospace fonts to use.";
        };

        sansSerif = mkOption {
          type = listOf str;
          default = [
            "Lexend"
            "Noto Color Emoji"
          ];
          description = "The sans-serif fonts to use.";
        };

        serif = mkOption {
          type = listOf str;
          default = [
            "Noto Serif"
            "Noto Color Emoji"
          ];
          description = "The serif fonts to use.";
        };

        emoji = mkOption {
          type = listOf str;
          default = [ "Noto Color Emoji" ];
          description = "The emoji fonts to use.";
        };

        gtk = {
          name = "Sans";
          size = 9;
        };
      };
    };

    desktopEnvironment = {
      desktopManager = mkOption {
        type = str;
        default = "hyprland";
        description = "Name of the desktop environment manager";
      };

      displayManager = mkOption {
        type = str;
        default = "sddm";
        description = "Name of the display manager";
      };

      displayServer = mkOption {
        type = enum [
          "wayland"
          "x11"
        ];
        default = "wayland";
        description = "Server to use. Acceptable values: wayland, x11";
      };
    };

    launcher = {
      modifier = mkOption {
        type = str;
        default = "SUPER";
        description = "Modifier key for window managers";
      };
      primary = {
        name = mkOption {
          type = str;
          default = "rofi";
          description = "Launcher name";
        };
        command = mkOption {
          type = str;
          default = "rofi -show-icons -show drun";
          description = "Launcher command";
        };
      };
      secondary = {
        name = mkOption {
          type = str;
          default = "anyrun";
          description = "SeconLauncher name";
        };
        command = mkOption {
          type = str;
          default = "anyrun";
          description = "Launcher command";
        };
      };
    };

    terminal = {
      primary = mkOption {
        type = str;
        default = "foot";
        description = "Primary terminal emulator";
      };
      secondary = mkOption {
        type = str;
        default = "wezterm";
        description = "Secondary terminal emulator";
      };
      tertiary = mkOption {
        type = str;
        default = "kitty";
        description = "Teritiary terminal emulator";
      };
    };

    # browser = mkOption {
    #   type = submodule (
    #     { config, ... }:
    #     {
    #       options = {
    #         primary = mkOption {
    #           name = "Firefox";
    #           inherit (firefox.options) package command;
    #         };
    #         secondary = mkOption {
    #           name = "Brave";
    #           package = pkgs.brave-browser-bin;
    #           command = "brave";
    #         };
    #         tertiary = mkOption {
    #           name = "Chromium";
    #           inherit (chromium.options) package command;
    #         };
    #       };
    #       config = {
    #         primary = config.primary.config;
    #         secondary = config.secondary.config;
    #         tertiary = config.tertiary.config;
    #       };
    #     }
    #   );
    # };

    firefox = rec {
      options = {
        package = mkOption { type = package; };
        command = mkOption { type = str; };
        edition = mkOption {
          type = enum [
            "main"
            "dev"
            "esr"
            "beta"
            "floorp"
            "librewolf"
          ];
          default = "dev";
          description = "Firefox edition to use.";
        };
      };
      config = {
        package = config.components.${config.edition}.package;
        command = config.components.${config.edition}.command;
      };
    };

    chromium = rec {
      options = {
        package = mkOption { type = package; };
        command = mkOption { type = str; };
        edition = mkOption {
          type = enum [
            "main"
            "dev"
            "beta"
            "edge"
            "chrome"
          ];
          default = "dev";
          description = "Chromium edition to use.";
        };
      };
      config = {
        package = config.components.${config.edition}.package;
        command = config.components.${config.edition}.command;
      };
    };

    editor = mkOption {
      type = submodule {
        options = {
          primary = mkOption {
            type = submodule (
              { config, ... }:
              {
                options = {
                  package = mkOption { type = package; };
                  command = mkOption { type = str; };
                  name = mkOption { type = str; };
                };
                config = {
                  name = "Display-aware Editor";
                };
              }
            );
          };
          secondary = mkOption {
            type = submodule (
              { config, ... }:
              {
                options = {
                  package = mkOption { type = package; };
                  command = mkOption { type = str; };
                  name = mkOption { type = str; };
                };
                config = {
                  name = "VSCode";
                };
              }
            );
          };
          tertiary = mkOption {
            type = submodule (
              { config, ... }:
              {
                options = {
                  package = mkOption { type = package; };
                  command = mkOption { type = str; };
                  name = mkOption { type = str; };
                };
                config = {
                  name = "Helix";
                };
              }
            );
          };
        };
        config = {
          primary = {
            package = pkgs.writeShellScriptBin "open" ''
              exec "${config.dots.paths.bin}/open" "$@"
            '';
            command = "open";
          };
          secondary = {
            package = pkgs.vscode-fhs;
            command = "code";
          };
          tertiary = {
            package = pkgs.helix;
            command = "hx";
          };
        };
      };
    };
  };

  config = mkIf (cfg.enable || cfg.isAdmin) {

    users.users.${user} = {
      inherit (cfg)
        description
        uid
        isNormalUser
        hashedPassword
        extraGroups
        ;
    };

    home-manager.users.${user} = {
      imports =
        let
          inherit (dots.paths) pkgs;
        in
        [
          # (programs + "/brave")
          # (programs + "/eza")
          # (programs + "/firefox")
          # (programs + "/git")
          # (programs + "/foot")
          # (programs + "/hyprland")
          (pkgs + "/helix")
          # (programs + "/utilities")
          # (programs + "/vscode")
        ];
    };
  };
}
