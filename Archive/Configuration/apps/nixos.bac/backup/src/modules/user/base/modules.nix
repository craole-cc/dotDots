{
  config,
  lib,
  pkgs,
  ...
}:
let
  #| Internal Imports
  inherit (config.DOTS)
    Active
    Enums
    Sources
    # Users
    ;
  inherit (Active) host;
  wallpapers = Sources.assets.pictures.home;

  #| External Imports
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.lists)
    length
    any
    elem
    elemAt
    findFirst
    isList
    ;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.strings) substring;
  inherit (lib.types)
    package
    nullOr
    bool
    str
    strMatching
    float
    enum
    attrs
    listOf
    int
    submodule
    nonEmptyListOf
    passwdEntry
    ints
    path
    shellPackage
    either
    attrsOf
    oneOf
    number
    ;

  inherit (pkgs) fetchFromGitHub;
in
# apps =
#   let
#     home = ../../app;
#   in
#   {
#     bat = import (home + "/bat") { };
#     btop = import (home + "/btop") { };
#     dunst = import (home + "/dunst") { };
#     firefox = import (home + "/firefox") { };
#     git = import (home + "/git") { };
#     helix = import (home + "/helix") { };
#     hyprland = import (home + "/hyprland") { };
#     microsoft-edge = import (home + "/microsoft-edge") { };
#     rofi = import (home + "/rofi") { };
#     waybar = import (home + "/waybar") { };
#   };
{
  options.DOTS.Modules.user = mkOption {
    description = "Module options for each user";
    default =
      _user: _path:
      let
        ARGS = {
          inherit config pkgs lib;
          inherit (config) DOTS;
          inherit (Active) host;
          # USER = Users.${_user};
          LIBS = config.DOTS.Libraries;
        };
      in
      with ARGS.USER;
      {

        enable = mkOption {
          description = "Enable user: ${name}";
          default = elem name (map (u: u.name) host.people);
          type = bool;
        };

        name = mkOption {
          description = "Name of the user";
          default = _user;
        };

        # apps = import ../components/apps { inherit ARGS; };
        # inherit (import ../../app { inherit args; }) applications;

        isNormalUser = mkOption {
          description = "Allow the user to login";
          default = true;
          type = bool;
        };

        paths = with paths; {
          conf = mkOption {
            description = "Path to the configuration";
            default = _path;
          };

          homeDirectory = mkOption {
            description = "The location of the user's home directory";
            default = "/home/${name}";
            type = path;
          };

          toLink = mkOption {
            description = "Script and binary folders to add to the PATH variable";
            type = listOf path;
            default = [ ];
          };

          pictures = mkOption {
            description = "The location of the user's pictures";
            default = homeDirectory + "/Pictures";
            type = path;
          };

          wallpapers = mkOption {
            description = "The location of the user's wallpapers";
            default = pictures + "/Wallpapers";
            type = path;
          };

          music = mkOption {
            description = "The location of the user's music";
            default = homeDirectory + "/Music";
            type = path;
          };

          videos = mkOption {
            description = "The location of the user's videos";
            default = homeDirectory + "/Videos";
            type = path;
          };

          tutorials = mkOption {
            description = "The location of the tutorial videos";
            default = videos + "/Tutorials";
            type = path;
          };

          downloads = mkOption {
            description = "The location of the user's downloads";
            default = homeDirectory + "/Downloads";
            type = path;
          };

          projects = mkOption {
            description = "The location of the user's projects";
            default = homeDirectory + "/Documents";
            type = path;
          };
        };

        id = mkOption {
          description = "The unique id number withing the range of `1000` to `59999`";
          default = null;
          example = "1000";
          type = nullOr (ints.between 1000 59999);
        };

        description = mkOption {
          description = "User's description";
          default = "${name}@${host.name}";
          type = str;
        };

        stateVersion = mkOption {
          description = "The NixOS installation version";
          default = substring 0 5 host.stateVersion;
        };

        groups = mkOption {
          description = "The user's main groups.";
          default =
            let
              userInfo = findFirst (u: u.name == _user) {
                name = _user;
                isElevated = false;
              } host.people;
            in
            if isNormalUser then
              (
                [ "users" ]
                ++ (if userInfo.isElevated then [ "wheel" ] else [ ])
                ++ (if !isMinimal then [ "networkmanager" ] else [ ])
              )
            else
              [ ];
          type = listOf str;
        };

        extraGroups = mkOption {
          description = "The user's auxiliary groups.";
          default = [ ];
          type = listOf str;
        };

        hashedPassword = mkOption {
          description = "Use `mkpasswd` to generate a hash of the user's password";
          default = null;
          type = nullOr (passwdEntry str);
        };

        context = mkOption {
          description = "The main role of the user in the {context}";
          default = null;
          type = nullOr (listOf (enum host.contextAllowed));
        };

        allowUnfree = mkOption {
          description = "Allow unfree packages";
          default = true;
          type = bool;
        };

        isMinimal = mkOption {
          description = "Minimal installation";
          default =
            context == null
            || (length context == 1 && elemAt context 0 == "minimal")
            || host.machine == "server";
          type = bool;
        };

        language = mkOption {
          description = "The default local for language processing.";
          default = "en_US.UTF-8";
          type = str;
        };

        packages = mkOption {
          description = "List of packages to install.";
          type = listOf package;
          default =
            let
              tui = with pkgs; [ ];
              gui = with pkgs; [
                cowsay
                neofetch
                btop
              ];
            in
            with pkgs;
            if isMinimal then tui else tui ++ gui; # TODO install packages from apps;
        };

        programs = mkOption {
          description = "List of packages to install.";
          default = { };
          type = attrs;
        };

        desktop = with desktop; {
          manager = mkOption {
            description = "The desktop/window manager";
            default = if isMinimal then null else "hyprland";
            type = nullOr (enum Enums.user.desktop.manager);
          };

          taskbar = mkOption {
            description = "The taskbar/statusbar for the desktop";
            default =
              if
                elem manager [
                  "hyperland"
                  "sway"
                  "river"
                ]
              then
                "waybar"
              else
                null;
            type = nullOr (either str path);
          };

          server = mkOption {
            description = "The windowing server";
            default =
              if manager == null then
                null
              else if
                elem manager [
                  "hyprland"
                  "kde"
                  "gnome"
                ]
              then
                "wayland"
              else
                "x11";
            type = nullOr (enum Enums.user.desktop.server);
          };
        };

        display = {
          autoLogin = mkEnableOption "Enable auto login";

          manager = mkOption {
            description = "The login manager";
            default =
              if isMinimal || desktop.manager == null then
                "kmscon"
              else if desktop.manager == "gnome" then
                "gdm"
              else if
                desktop.server == "x11"
                || elem desktop.manager [
                  "pantheon"
                  "xfce"
                ]
              then
                "lightdm"
              else
                "sddm";
            type = enum Enums.user.display.manager;
          };
        };

        fonts = with fonts; {
          nerdfonts = with nerdfonts; {
            fonts = mkOption {
              description = "Fonts to install from nerdfonts";
              default = [ "JetBrainsMono" ];
            };
            package = mkOption {
              description = "The font package to use.";
              default = pkgs.nerdfonts.override { fonts = fonts; };
              type = package;
            };
          };

          awesome = mkOption {
            package = mkOption {
              default = fetchFromGitHub {
                owner = "rng70";
                repo = "Awesome-Fonts";
                rev = "3733f56e431608878d6cbbf2d70d8bf36ab2c226";
                sha256 = "0m41gdgp06l5ymwvy0jkz6qfilcz3czx416ywkq76z844y5xahd0";
              };
            };
          };

          console = with console; {
            size = mkOption {
              description = "Font size";
              default = 14;
              type = int;
            };

            packages = mkOption {
              description = "The font to use in the console";
              default = [ pkgs.terminus_font ];
              type = listOf package;
            };

            font = mkOption {
              description = "The font to use in the console";
              default = "ter-u${toString (size + 10)}n";
              type = str;
            };

            sets = mkOption {
              description = "Fonts to use in the console";
              default = [
                {
                  name = "JetBrainsMono Nerd Font";
                  package = nerdfonts.package;
                }
                {
                  name = "Source Code Pro";
                  package = pkgs.source-code-pro;
                }
              ];
              type =
                let
                  font = submodule {
                    options = {
                      name = mkOption {
                        description = "Font name, as used by fontconfig.";
                        type = str;
                      };
                      package = mkOption {
                        description = "Package providing the font.";
                        type = package;
                      };
                    };
                  };
                in
                nonEmptyListOf font;
            };
          };

          packages = mkOption {
            type = listOf package;
            default = with pkgs; [
              nerdfonts.package
              awesome.package

              lexend
              material-design-icons
              material-icons
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
            description = "The emoji fonts to use.";
            default = [ "Noto Color Emoji" ];
            type = listOf str;
          };

          gtk = {
            name = mkOption {
              description = "The name of the GTK font";
              default = "Sans";
              type = nullOr str;
            };
            size = mkOption {
              description = "The size of the GTK font";
              default = 10;
              type = nullOr number;
            };
            package = mkOption {
              description = "The package providing the GTK font";
              default = null;
              type = nullOr package;
            };
          };
        };

        colors = with colors; {
          mode = mkOption {
            description = "The color mode to use.";
            # default = "dark";
            default = "light";
            type = enum [
              "dark"
              "light"
            ];
          };

          scheme = with scheme; {
            dark = mkOption {
              description = "The dark color scheme to use.";
              default = "darkGruvbox";
              type = str;
            };

            light = mkOption {
              description = "The light color scheme to use.";
              default = "lightGruvbox";
              type = str;
            };

            default = mkOption {
              description = "The default color scheme to use.";
              default = if mode == "dark" then dark else light;
              type = str;
            };
          };

          console = mkOption {
            description = "Console colors in hexadecimal format and listed in  order from color 0 to color 15.";
            default = [
              "303446"
              "292c3c"
              "414559"
              "51576d"
              "626880"
              "c6d0f5"
              "f2d5cf"
              "babbf1"
              "e78284"
              "ef9f76"
              "e5c890"
              "a6d189"
              "81c8be"
              "8caaee"
              "ca9ee6"
              "eebebe"
            ];
            type = listOf (strMatching "[[:xdigit:]]{6}");
          };
        };

        wallpaper = {
          light = mkOption {
            description = "The light wallpaper to use.";
            default = wallpapers + "/wallpaper-light.jpg";
            type = path;
          };

          dark = mkOption {
            description = "The dark wallpaper to use.";
            default = wallpapers + "/wallpaper-dark.jpg";
            type = path;
          };

          default =
            with wallpaper;
            with colors;
            mkOption {
              description = "The default wallpaper to use.";
              default = if mode == "dark" then dark else light;
              type = path;
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
                type = package;
                default = pkgs.vscode-extensions.pkief.material-icon-theme;
              };
            };
            productIconTheme = {
              name = mkOption {
                type = types.str;
                default = "material-product-icons";
              };
              package = mkOption {
                type = package;
                default = pkgs.vscode-extensions.pkief.material-product-icons;
              };
            };
          };

          gtk = {
            package = mkOption {
              description = "GTK theme package.";
              default = pkgs.catppuccin-papirus-folders;
              type = package;
            };
            name = mkOption {
              type = str;
              default = "Papirus";
              description = "GTK theme name.";
            };
          };
        };

        sessionVariables = mkOption {
          default = {
            EDITOR = "nvim";
            VISUAL = "nvim";
          };
          description = ''
            A set of environment variables used in the global environment.
            These variables will be set on shell initialisation (e.g. in /etc/profile).
            The value of each variable can be either a string or a list of
            strings.  The latter is concatenated, interspersed with colon
            characters.
          '';
          type = attrsOf (oneOf [
            (listOf (oneOf [
              float
              int
              str
            ]))
            float
            int
            str
            path
          ]);
          apply = mapAttrs (n: v: if isList v then concatMapStringsSep ":" toString v else toString v);
        };

        shellAliases = mkOption {
          default = {
            l = null;
            ll = "ls -l";
          };
          description = ''
            An attribute set that maps aliases (the top level attribute names in
            this option) to command strings or directly to build outputs. The
            aliases are added to all users' shells.
            Aliases mapped to `null` are ignored.
          '';
          type = attrsOf (nullOr (either str path));
        };

        input = {
          keyboard = {
            model = mkOption {
              description = "Appropriate XKB keymap parameter.";
              default = "";
              type = str;
            };

            layout = mkOption {
              description = "Appropriate XKB keymap parameter";
              default = "us";
              type = nullOr str;
            };

            variant = mkOption {
              description = "Appropriate XKB keymap parameter";
              default = "";
              type = str;
            };

            options = mkOption {
              description = "Appropriate XKB keymap parameter";
              default =
                if
                  (elem host.machine [
                    "laptop"
                    "raspberry-pi"
                    "server"
                  ])
                then
                  "caps:swapescape"
                else
                  "";
              type = str;
            };

            rules = mkOption {
              description = "Appropriate XKB keymap parameter";
              default = "";
              type = str;
            };

            file = mkOption {
              description = "If you prefer, you can use a path to your custom .xkb file.";
              default = "";
              type = either path str;
            };

            numlockByDefault = mkOption {
              description = "Engage numlock by default.";
              default = false;
              type = bool;
            };

            resolveBindsBySym = mkOption {
              description = "Determines how keybinds act when multiple layouts are used. If false, keybinds will always act as if the first specified layout is active. If true, keybinds specified by symbols are activated when you type the respective symbol with the current layout.";
              default = false;
              type = bool;
            };

            repeatRate = mkOption {
              description = "The repeat rate for held-down keys, in repeats per second.";
              default = 25;
              type = int;
            };

            repeatDelay = mkOption {
              description = "Delay before a held-down key is repeated, in milliseconds.";
              default = 600;
              type = int;
            };
          };

          mouse = {
            acceleration = mkOption {
              description = "Sets the cursor acceleration profile. Can be one of adaptive, flat. Can also be custom, see below. Leave empty to use libinput's default mode for your input device. libinput#pointer-acceleration [adaptive/flat/custom]";
              default = "flat";
              type = enum [
                "adaptive"
                "flat"
                "custom"
              ];
            };

            floatSwitchOverrideFocus = mkOption {
              description = ''
                Changes the focus when switching between tiled-to-floating and floating-to-tiled.
                0 - Focus will not change
                1 - Focus will change to the window under the cursor
                2 - Focus will also follow mouse on float-to-float switches.
              '';
              default = 1;
              type = enum [
                0
                1
                2
              ];
            };

            follow = mkOption {
              description = ''
                Specify if and how cursor movement should affect window focus.
                0 - Cursor movement will not change focus.
                1 - Cursor movement will always change focus to the window under the cursor.
                2 - Clicking on a window will move keyboard focus to that window.
                3 - Clicking on a window will not change keyboard focus
              '';
              default = 1;
              type = enum [
                0
                1
                2
                3
              ];
            };

            forceNoAccel = mkOption {
              description = "Force no cursor acceleration. This bypasses most of your pointer settings to get as raw of a signal as possible. Enabling this is not recommended due to potential cursor desynchronization.";
              default = false;
              type = bool;
            };

            leftHanded = mkOption {
              description = "Switches RMB and LMB";
              default = false;
              type = bool;
            };

            offWindowAxisEvents = mkOption {
              description = ''
                Handles axis events around a focused window.
                0 - Ignores axis events.
                1 - Sends out-of-bound coordinates.
                2 - Fakes pointern coordinates to the closest point inside the window.
                3 - Wraps the cursor to the closest point inside the window..
              '';
              default = 1;
              type = enum [
                0
                1
                2
                3
              ];
            };
            refocus = mkOption {
              description = "If disabled, mouse focus won't switch to the hovered window unless the mouse crosses a window boundary when follow_mouse=1.";
              default = true;
              type = bool;
            };

            scroll = {
              button = mkOption {
                description = "Sets the scroll button. Has to be an int, cannot be a string. Check wev if you have any doubts regarding the ID. 0 means default.";
                default = 0;
                type = int;
              };

              buttonLock = mkOption {
                description = "If the scroll button lock is enabled, the button does not need to be held down. Pressing and releasing the button toggles the button lock, which logically holds the button down or releases it. While the button is logically held down, motion events are converted to scroll events.";
                default = false;
                type = bool;
              };

              factor = mkOption {
                description = "Multiplier added to scroll movement for external mice. Note that there is a separate setting for touchpad scroll_factor.";
                default = 1.0;
                type = float;
              };

              points = mkOption {
                description = "Sets the scroll acceleration profile, when accel_profile is set to custom. Has to be in the form <step> <points>. Leave empty to have a flat scroll curve.";
                default = "";
                type = str;
                example = "custom 200 0.0 0.5";
              };

              method = mkOption {
                description = "Sets the scroll method.";
                default = "2fg";
                type = enum [
                  "2fg"
                  "edge"
                  "on_button_down"
                  "no_scroll"
                ];
              };

              natural = mkOption {
                description = "Inverts scrolling direction. When enabled, scrolling moves content directly, rather than manipulating a scrollbar.";
                default = false;
                type = bool;
              };
            };

            sensitivity = mkOption {
              description = "Sets the mouse input sensitivity. Value is clamped to the range -1.0 to 1.0. libinput#pointer-acceleration";
              default = 0.0;
              type = float;
            };

            specialFallthrough = mkOption {
              description = "If enabled, special mouse buttons will fall through to the window under the cursor. libinput#pointer-fall-through";
              default = false;
              type = bool;
            };
          };

          touchpad = {
            disableWhileTyping = mkOption {
              description = "Disable the touchpad while typing.";
              default = true;
              type = bool;
            };

            middleButtonEmulation = mkOption {
              description = "Sending LMB and RMB simultaneously will be interpreted as a middle click. This disables any touchpad area that would normally send a middle click based on location. libinput#middle-button-emulation";
              default = false;
              type = bool;
            };

            clickfingerBehavior = mkOption {
              description = "Button presses with 1, 2, or 3 fingers will be mapped to LMB, RMB, and MMB respectively. This disables interpretation of clicks based on location on the touchpad. libinput#clickfinger-behavior";
              default = false;
              type = bool;
            };

            dragLock = mkOption {
              description = "When enabled, lifting the finger off for a short time while dragging will not drop the dragged item. libinput#tap-and-drag";
              default = false;
              type = bool;
            };

            scroll = {
              factor = mkOption {
                description = "Multiplier applied to the amount of scroll movement.";
                default = 1.0;
                type = float;
              };

              natural = mkOption {
                description = "Inverts scrolling direction. When enabled, scrolling moves content directly, rather than manipulating a scrollbar.";
                default = false;
                type = bool;
              };
            };

            tap = {
              toClick = mkOption {
                description = "Tapping on the touchpad with 1, 2, or 3 fingers will send LMB, RMB, and MMB respectively.";
                default = true;
                type = bool;
              };

              buttonMap = mkOption {
                description = "Sets the tap button mapping for touchpad button emulation. Can be one of lrm (default) or lmr (Left, Middle, Right Buttons).";
                default = "lrm";
                type = enum [
                  "lrm"
                  "lmr"
                ];
              };

              toDrag = mkOption {
                description = "Sets the tap and drag mode for the touchpad.";
                default = false;
                type = bool;
              };
            };
          };

          touchdevice = {
            enabled = mkOption {
              description = "Whether input is enabled for touch devices.";
              default = true;
              type = bool;
            };

            # output = mkOption {
            #   description = "The monitor to bind touch devices.The default is auto-detected.";
            #   default = "[[Auto]]";
            #   type = str;
            # };

            transform = mkOption {
              description = "Transform the input from touch devices. The possible transformations are the same as those of the monitors.";
              default = 0;
              type = int;
            };
          };

          tablet = {
            activeArea = {
              size = mkOption {
                description = "Size of tablet's active area in mm.";
                default = [
                  0
                  0
                ];
                type = listOf int;
              };
              position = mkOption {
                description = "Position of the active area in mm.";
                default = [
                  0
                  0
                ];
                type = listOf int;
              };
            };
            leftHanded = mkOption {
              description = "If enabled, the tablet will be rotated 180 degrees.";
              default = false;
              type = bool;
            };

            # output = mkOption {
            #   description = "The monitor to bind touch devices.The default is auto-detected.";
            #   default = null;
            #   type = nullOr int;
            # };

            region = {
              position = mkOption {
                description = "Position of the mapped region in monitor layout.";
                default = [
                  0
                  0
                ];
                type = listOf int;
              };
              size = mkOption {
                description = "Size of the mapped region. When this variable is set, tablet input will be mapped to the region. [0, 0] or invalid size means unset.";
                default = [
                  0
                  0
                ];
                type = listOf int;
              };
            };
            relativeInput = mkOption {
              description = "Whether the input should be relative.";
              default = false;
              type = bool;
            };
            transform = mkOption {
              description = "Transform the input from tablets. The possible transformations are the same as those of the monitors.";
              default = 0;
              type = int;
            };
          };
        };

        # applications = with apps; {
        #   # inherit (bat.options args) bat;
        #   # inherit (btop.module args) btop;
        #   # inherit (dunst.module args) dunst;
        #   # inherit (firefox.module args) firefox;
        #   # inherit (git.module args) git;
        #   # inherit (helix.module args) helix;
        #   # inherit (hyprland.module args) hyprland;
        #   # inherit (microsoft-edge.module args) microsoft-edge;
        #   # inherit (rofi.module args) rofi;
        #   # inherit (waybar.module args) waybar;

        #   programs = mkOption {
        #     default = with applications; {
        #       # bat = bat.export;
        #       # btop = btop.export;
        #       # firefox = firefox.export;
        #       # git = git.export;
        #       # helix = helix.export;
        #       # rofi = rofi.export;
        #     };
        #   };

        #   packages = mkOption {
        #     default = with applications; {
        #       # bat = bat.export.package;
        #       # btop = btop.export.package;
        #       # firefox = firefox.export.package;
        #       # git = git.export.package;
        #       # helix = helix.export.package;
        #       # rofi = rofi.export.package;
        #     };
        #   };

        #   launcher = {
        #     modifier = mkOption {
        #       description = "Modifier key for window managers";
        #       default = "SUPER";
        #       type = str;
        #     };
        #     primary = {
        #       name = mkOption {
        #         type = str;
        #         default = "rofi";
        #         description = "Launcher name";
        #       };
        #       package = mkOption {
        #         description = "Package name";
        #         default = pkgs.rofi;
        #         type = package;
        #       };
        #       command = mkOption {
        #         type = str;
        #         default = "rofi -show-icons -show drun";
        #         description = "Launcher command";
        #       };
        #     };
        #     secondary = {
        #       name = mkOption {
        #         description = "Secondary launcher name";
        #         default = "anyrun";
        #         type = str;
        #       };
        #       command = mkOption {
        #         description = "Secondary launcher command";
        #         default = "anyrun";
        #         type = str;
        #       };
        #     };
        #   };

        #   terminal = {
        #     primary = {
        #       name = mkOption {
        #         description = "Terminal name";
        #         default = "foot";
        #         type = str;
        #       };

        #       package = mkPackageOption pkgs "foot" { };

        #       command = mkOption {
        #         description = "Launcher command";
        #         default = "footclient";
        #         type = str;
        #       };
        #     };
        #     secondary = {
        #       name = mkOption {
        #         description = "Terminal name";
        #         default = "warp-terminal";
        #         type = str;
        #       };

        #       package = mkPackageOption pkgs "warp-terminal" { };

        #       command = mkOption {
        #         description = "Terminal command";
        #         type = str;
        #         default = "warp-terminal";
        #       };
        #     };
        #   };

        #   editor = {
        #     primary = {
        #       name = mkOption {
        #         description = "Editor name";
        #         default = "Editor";
        #         type = str;
        #       };

        #       package = mkPackageOption pkgs "helix" { };

        #       command = mkOption {
        #         description = "Editor command";
        #         type = str;
        #         default = "ede";
        #       };
        #     };

        #     secondary = {
        #       name = mkOption {
        #         type = str;
        #         default = "code";
        #         description = "Editor name";
        #       };

        #       package = mkPackageOption pkgs "vscode-fhs" { };

        #       command = mkOption {
        #         description = "Launcher command";
        #         type = str;
        #         default = "code";
        #       };
        #     };
        #   };

        #   browser = {
        #     primary = {
        #       name = mkOption {
        #         type = str;
        #         default = "firefox-bin";
        #         description = "Launcher name";
        #       };

        #       package = mkPackageOption pkgs "firefox-devedition-bin" { };

        #       command = mkOption {
        #         type = str;
        #         default = "firefox-developer-edition";
        #         description = "Launcher command";
        #       };
        #     };

        #     secondary = {
        #       name = mkOption {
        #         type = str;
        #         default = "Microsoft Edge";
        #         description = "Secondary Browser";
        #       };

        #       package = mkPackageOption pkgs "microsoft-edge-dev" { };

        #       command = mkOption {
        #         type = str;
        #         default = "microsoft-edge-dev";
        #         description = "Secondary Browser";
        #       };
        #     };
        #   };

        #   shell = mkOption {
        #     description = "The user's shell";
        #     default = null;
        #     type = nullOr (either shellPackage (passwdEntry path));
        #   };
        # };
      };
  };
}
