{
  config,
  lib,
  pkgs,
  ...
}:
let
  #| Native Imports
  inherit (lib.attrsets)
    filterAttrs
    attrNames
    attrValues
    mapAttrs
    isAttrs
    ;
  inherit (lib.lists)
    length
    head
    any
    elem
    elemAt
    findFirst
    isList
    ;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.strings) concatStringsSep substring;
  inherit (lib.types)
    nonEmptyStr
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
    raw
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

  #| Extended Imports
  inherit (config) DOTS;
  base = "modules";
  mod = "user";

  inherit (DOTS.active) host;
  inherit (DOTS) users;
in
{
  options.DOTS.${base}.${mod} = mkOption {
    description = "{{mod}}s in {{base}}";
    default =
      userName: userConfig:
      # with users.${userName};
      # with enums;
      {
        enable = mkOption {
          description = "Enable user: ${name}";
          default = elem name (map (u: u.name) host.people);
          type = bool;
        };

        name = mkOption {
          description = "Name of the user";
          default = userName;
        };

        isNormalUser = mkOption {
          description = "Allow the user to login";
          default = true;
          type = bool;
        };

        paths = with paths; {
          conf = mkOption {
            description = "Path to the configuration";
            default = userConfig;
          };

          homeDirectory = mkOption {
            description = "The location of the userNames home directory";
            default = "/home/${name}";
            type = path;
          };

          toLink = mkOption {
            description = "Script and binary folders to add to the PATH variable";
            type = listOf path;
            default = [ ];
          };

          pictures = mkOption {
            description = "The location of the userNames pictures";
            default = homeDirectory + "/Pictures";
            type = path;
          };

          wallpapers = mkOption {
            description = "The location of the userNames wallpapers";
            default = pictures + "/Wallpapers";
            type = path;
          };

          music = mkOption {
            description = "The location of the userNames music";
            default = homeDirectory + "/Music";
            type = path;
          };

          videos = mkOption {
            description = "The location of the userNames videos";
            default = homeDirectory + "/Videos";
            type = path;
          };

          tutorials = mkOption {
            description = "The location of the tutorial videos";
            default = videos + "/Tutorials";
            type = path;
          };

          downloads = mkOption {
            description = "The location of the userNames downloads";
            default = homeDirectory + "/Downloads";
            type = path;
          };

          projects = mkOption {
            description = "The location of the userNames projects";
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
          description = "userNames description";
          default = "${name}@${host.name}";
          type = str;
        };

        stateVersion = mkOption {
          description = "The NixOS installation version";
          default = substring 0 5 host.stateVersion;
        };

        groups = mkOption {
          description = "The userNames main groups.";
          default =
            let
              userInfo = findFirst (u: u.name == userName) {
                name = userName;
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
          description = "The userNames auxiliary groups.";
          default = [ ];
          type = listOf str;
        };

        hashedPassword = mkOption {
          description = "Use `mkpasswd` to generate a hash of the userNames password";
          default = null;
          type = nullOr (passwdEntry str);
        };

        shell = mkOption {
          description = "The userNames shell";
          default = null;
          type = nullOr (either shellPackage (passwdEntry path));
        };

        context = mkOption {
          description = "The main role of the user in the {context}";
          # default = lib.toList (elemAt (host.contextAllowed) 0);
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
          default = (length context == 1 && elemAt context 0 == "minimal") || host.machine == "server";
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
          default = with pkgs; [ cowsay ];
        };

        programs = mkOption {
          description = "List of packages to install.";
          default = { };
          type = attrs;
        };

        desktop = with desktop; {
          manager = mkOption {
            description = "The desktop/window manager";
            default = null;
            type = nullOr (enum enums.user.desktop.manager);
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
            type = nullOr (enum enums.user.desktop.server);
          };
        };

        display = {
          autoLogin = mkEnableOption "Enable auto login";

          manager = mkOption {
            description = "The login manager";
            default =
              if host.isMinimal || desktop.manager == null then
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
            type = enum enums.user.display.manager;
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

        applications = with applications; {
          launcher = {
            modifier = mkOption {
              description = "Modifier key for window managers";
              default = "SUPER";
              type = str;
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
              default = "foot";
              description = "Primary terminal emulator";
              type = str;
            };
            secondary = mkOption {
              default = "wezterm";
              description = "Secondary terminal emulator";
              type = str;
            };
            tertiary = mkOption {
              default = "kitty";
              description = "Teritiary terminal emulator";
              type = str;
            };
          };

          editor = {
            primary = mkOption {
              description = "The primary code editor";
              default = "code";
              type = str;
            };
            secondary = mkOption {
              description = "The primary code editor";
              default = "codium";
              type = str;
            };
          };

          browser = {
            primary = {
              name = mkOption {
                type = str;
                default = "firefox";
                description = "Launcher name";
              };
              command = mkOption {
                type = str;
                default = "firefox-developer-edition";
                description = "Launcher command";
              };
            };

            secondary = {
              name = mkOption {
                type = str;
                default = "Microsoft Edge";
                description = "Secondary Browser";
              };
              command = mkOption {
                type = str;
                default = "microsoft-edge-dev";
                description = "Secondary Browser";
              };
            };
          };

          bat = {
            enable = mkEnableOption "bat";
            package = mkPackageOption pkgs "bat" { };
            config = mkOption { default = { }; };
            themes = mkOption { default = { }; };
            syntaxes = mkOption { default = { }; };

            export = mkOption {
              default = {
                inherit (bat)
                  enable
                  package
                  config
                  themes
                  ;
              };
            };
          };

          btop = {
            enable = mkEnableOption "btop";
            package = mkPackageOption pkgs "btop" { };
            export = mkOption { default = if btop.enable then { inherit (btop) enable package; } else { }; };
          };

          git = with git; {
            enable = mkEnableOption "Git" // {
              default =
                let
                  isRequired =
                    context != null
                    && any (
                      name:
                      elem name [
                        "development"
                        # "productivity"
                      ]
                    ) context;
                  isRequested = userName != null && userEmail != null;
                in
                isRequested;
              # isRequested || isRequired;
            };

            # enable = mkEnableOption "Git" // {
            #   default = userName != null && userEmail != null ;
            # };

            name = mkOption {
              description = "Git username";
              default = null;
              type = nullOr str;
            };

            email = mkOption {
              description = "Git enail";
              default = null;
              type = nullOr str;
            };

            sshKey = mkOption {
              description = "Git ssh key";
              default = null;
              type = nullOr str;
            };

            aliases = mkOption { default = { }; };
            attributes = mkOption { default = [ ]; };
            delta = mkOption { default = { }; };
            diff-so-fancy = mkOption { default = { }; };
            difftastic = mkOption { default = { }; };
            extraConfig = mkOption { default = { }; };
            hooks = mkOption { default = { }; };
            ignores = mkOption { default = [ ]; };
            includes = mkOption { default = [ ]; };
            iniContent = mkOption { default = { }; };
            lfs.enable = mkOption { default = enable; };
            package = mkPackageOption pkgs "gitFull" { };
            signing = null;
            userEmail = mkOption { default = email; };
            userName = mkOption { default = name; };

            export = mkOption {
              default =
                if git.enable then
                  {
                    inherit (git)
                      aliases
                      attributes
                      delta
                      diff-so-fancy
                      difftastic
                      enable
                      extraConfig
                      hooks
                      ignores
                      includes
                      iniContent
                      lfs
                      package
                      signing
                      userName
                      userEmail
                      ;
                  }
                else
                  { };
            };
          };

          helix = {
            enable = mkEnableOption "Helix Text Editor" // {
              default =
                context != null
                && any (
                  name:
                  elem name [
                    "minimal"
                    "development"
                  ]
                ) context;
            };

            defaultEditor = mkEnableOption "set as the default editor" // {
              default = helix.enable;
            };

            bindings = mkOption {
              default = {
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

            languages = mkOption {
              default = [
                {
                  name = "nix";
                  language-servers = [ "nil" ];
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
                    command = "black";
                    args = [
                      "-"
                      "-q"
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
            };

            settings = mkOption {
              default = {
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
            };

            export = mkOption {
              default =
                if helix.enable then
                  {
                    inherit (helix) enable defaultEditor;
                    languages.language = helix.languages;
                    settings = {
                      editor = helix.settings;
                      keys = helix.bindings;
                    };
                  }
                else
                  { };
            };
          };

          hyprland = {
            enable = mkEnableOption "Hyprland wayland compositor" // {
              default = desktop.manager == "hyprland";
            };

            package = mkPackageOption pkgs "hyprland" { };

            plugins = mkOption {
              description = "The Hyprland plugins to use";
              default = [ ];
              type = listOf (either package path);
            };

            settings = mkOption {
              description = "The Hyprland settings to use";
              default = { };
              type = attrs;
            };

            systemd = mkOption {
              description = "The Hyprland settings to use";
              default = { };
              type = attrs;
            };

            bindings = mkOption {
              default = {
                "k" = "kitty";
                "w" = "firefox";
              };
              type = attrs;
            };

            workspaces = mkOption {
              default = [
                "1"
                "2"
                "3"
                "4"
                "5"
                "6"
                "7"
                "8"
                "9"
                "F1"
                "F2"
                "F3"
                "F4"
                "F5"
                "F6"
                "F7"
                "F8"
                "F9"
                "F10"
                "F11"
                "F12"
              ];
              type = listOf str;
            };

            directions = mkOption {
              default = {
                # Map keys (arrows and hjkl) to hyprland directions (l, r, u, d)
                left = "l";
                right = "r";
                up = "u";
                down = "d";
                h = "l";
                l = "r";
                k = "u";
                j = "d";
              };
            };

            variables = mkOption {
              default = with host.processor; [
                "WLR_RENDERER_ALLOW_SOFTWARE, ${if gpu == "nvidia" || cpu == "vm" then "1" else "0"}"
                "WLR_NO_HARDWARE_CURSORS, ${if gpu == "nvidia" || cpu == "vm" then "1" else "0"}"
                "NIXPKGS_ALLOW_UNFREE, ${if allowUnfree then "1" else "0"}"

                "XDG_CURRENT_DESKTOP,Hyprland"
                "XDG_SESSION_TYPE,wayland"
                "XDG_SESSION_DESKTOP,Hyprland"

                "SDL_VIDEODRIVER,wayland" # Known to be problematic
                "CLUTTER_BACKEND, wayland"
                "GDK_BACKEND,wayland,x11"

                "QT_QPA_PLATFORM,wayland;xcb"
                "QT_WAYLAND_DISABLE_WINDOWDECORATION, 1"
                "QT_AUTO_SCREEN_SCALE_FACTOR, 1"

                "NIXOS_OZONE_WL,1"
                "MOZ_ENABLE_WAYLAND, 1"

                # "GTK_THEME=Adwaita-dark"
                # "XCURSOR_SIZE, 16"
                # "XCURSOR_THEME, Bibata-Modern-Ice"
                # "GTK_THEME=${gtk.name}"
                # "XCURSOR_SIZE,32"
                # "XCURSOR_SIZE,${(toString cursor.size)}"
                # "XCURSOR_THEME,${cursor.name}"
              ];
            };

            export = mkOption {
              default =
                if hyprland.enable then
                  {
                    inherit (hyprland) enable package plugins;
                    settings = {
                      env = hyprland.variables;
                    };
                  }
                else
                  { };
            };
          };
        };
      };
    type = raw;
  };
}
