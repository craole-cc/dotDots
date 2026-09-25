{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrNames attrValues listToAttrs mapAttrs;
  inherit (lib.lists) concatMap flatten head imap0;
  inherit (lib.modules) mkForce mkIf;
  inherit (lib.strings) concatMapStringsSep concatStringsSep readFile toUpper;
  inherit (lix.strings) capitalize;

  host = import ./.;
  lix = import ./lib.nix {inherit lib;};
  inputs = import ./sources.nix {
    inherit lix;
    inherit (host) system;
    inputs = lib.flake.inputs or {};
  };
in {
  imports =
    host.imports
    ++ (with inputs; [
      home-manager
      nix-index
      catppuccin
    ]);

  boot = {
    loader = with interface.boot.loader; {
      grub = {
        inherit device;
        enable = manager == "grub";
        useOSProber = true;
        fsIdentifier = "provided";
      };
      systemd-boot = {
        enable = manager == "systemd-boot";
        consoleMode = "max";
      };
      inherit timeout;
    };

    kernelPackages =
      pkgs.${args.packages.kernel or "linuxPackages_latest"};
  };

  catppuccin = {
    enable = true;
    autoEnable = true;
    inherit (aesthetics.primary.active) flavor accent;
  };

  console = {
    keyMap = principal.keyboard.layout;
  };

  documentation = {
    nixos.enable = false;
  };

  environment = {
    pathsToLink = mkIf interface.isPlasma ["/share/konsole"];
    plasma6.excludePackages = with pkgs.kdePackages; [
      khelpcenter
      # elisa
      # gwenview
    ];
    sessionVariables = variables;
    systemPackages = packages.forSystem;
  };

  fonts = let
    clock = {
      name = "Rubik";
      package = pkgs.rubik;
    };
    emoji = {
      name = "Noto Color Emoji";
      package = pkgs.noto-fonts-color-emoji;
    };
    material = {
      name = "Material Symbols Sharp";
      package = pkgs.material-symbols;
    };
    monospace = {
      name = "Maple Mono NF";
      package = pkgs.maple-mono.NF-unhinted;
    };
    sansSerif = {
      name = "Monaspace Radon Frozen";
      package = pkgs.monaspace;
    };
    serif = {
      name = "Noto Serif";
      package = pkgs.noto-fonts;
    };
  in {
    packages =
      [
        clock.package
        emoji.package
        material.package
        monospace.package
        sansSerif.package
        serif.package
      ]
      ++ (with pkgs.nerd-fonts; [
        jetbrains-mono
        zed-mono
      ]);
    fontconfig = {
      defaultFonts = {
        monospace = [monospace.name];
        sansSerif = [sansSerif.name];
        serif = [serif.name];
        emoji = [emoji.name];
      };
    };
  };
  i18n = {
    inherit (principal) defaultLocale;
  };

  networking = {
    hostName = name;
    hostId = id;
    networkmanager.enable = true;
  };

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nixPath = [
      "nixos-config=${variables.DOTS_BUILD}/configuration.nix"
      "nixpkgs=${sources.nixpkgs.path}"
    ];
  };

  nixpkgs = {
    pkgs = sources.nixpkgs;
  };

  programs = {
    bash = {
      enable = true;
      blesh.enable = true;
      undistractMe.enable = true;
    };

    bat = {
      enable = true;

      extraPackages = with pkgs.bat-extras; [
        batdiff
        batman
        prettybat
      ];

      settings = {};
    };

    dconf = {
      enable = true;
    };
    direnv = {
      enable = true;
      silent = true;
      angrr = {
        enable = true;
      };
    };

    git = {
      enable = true;
      lfs = {
        enable = true;
        enablePureSSHTransfer = true;
      };
      prompt.enable = true;
      config = let
        #? `git` is always an ordered list of identities; the head is the
        #? identity applied globally. No principal is expected to fall back
        # ? to a singular name/email pair anymore.
        primary = head (principal.git);
      in
        {
          user = {inherit (primary) name email;};
          init.defaultBranch = "main";
          safe.directory = [paths.dots];
          url."https://github.com/".insteadOf = ["gh:" "github:"];
          alias.project-summary = "!which onefetch && onefetch";
          push.autoSetupRemote = true;
        }
        // (primary.settings or {});
    };

    hyprland = {
      enable = interface.isHyprland;
      withUWSM = true;
    };

    hyprlock = {
      enable = interface.isHyprland;
    };

    iio-hyprland = {
      enable = interface.isHyprland;
    };

    kbdlight = {
      enable = true;
    };

    kdeconnect = {
      enable = true;
    };

    labwc = {
      enable = interface.isLab;
    };

    lazygit = {
      inherit (config.programs.git) enable;
    };

    less = {
      enable = true;
      envVariables = {
        LESS = "--quit-if-one-screen";
      };
    };

    mango = {
      enable = interface.isMango;
    };

    nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 7d --keep 3";
      };
      flake = paths.dots;
    };

    niri = {
      enable = interface.isNiri;
    };

    nix-index = {
      enable = true;
    };
    nix-index-database = {
      enable = true;
      comma.enable = true;
    };

    nix-ld = {
      enable = true;
    };

    starship = {
      enable = true;
      transientPrompt.enable = true;
      settings = fromTOML (readFile (
        sources.dots + "/Configuration/starship/config.toml"
      ));
    };
  };

  security = {
    sudo.extraRules = [
      {
        users = [principal.name];
        commands = [
          {
            command = "ALL";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];

    rtkit.enable = true;
  };

  services = {
    displayManager = {
      enable = true;
      defaultSession = mkForce (
        if interface.isPlasma
        then "plasma"
        else if interface.isNiri
        then "niri"
        else interface.defaultSession
      );

      autoLogin = {
        inherit (users.autoLogin) enable user;
      };

      plasma-login-manager = {
        enable = interface.isPlasma;
      };
    };

    desktopManager = {
      plasma6 = {
        enable = interface.isPlasma;
      };

      gnome = {
        enable = interface.isGnome;
      };

      cosmic = {
        enable = interface.isCosmic;
      };
    };

    xserver = {
      enable = interface.isX11;

      xkb = {
        inherit (principal.keyboard) layout variant;
      };
    };

    openssh = {
      enable = true;
    };

    tailscale = {
      enable = true;
    };

    libinput = {
      enable = true;
    };

    printing = {
      enable = true;
    };

    hypridle = {
      enable = interface.isHyprland;
    };

    fprintd = {
      enable = true;
    };

    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  system = {
    inherit stateVersion;
  };

  time = {
    timeZone = args.localization.timeZone or "America/Jamaica";
  };

  users.users = users.core;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {host = args;};
    users =
      mapAttrs (name: user: let
        aes = aesthetics.users.${name};
        modes = ["dark" "light"];

        #? Catppuccin colors for terminals that need an explicit palette (foot).
        #? Add macchiato/mocha here if you ever switch to those flavors.
        palette = {
          frappe = {
            rosewater = "f2d5cf";
            base = "303446";
            text = "c6d0f5";
            subtext0 = "a5adce";
            subtext1 = "b5bfe2";
            surface1 = "51576d";
            surface2 = "626880";
            red = "e78284";
            green = "a6d189";
            yellow = "e5c890";
            blue = "8caaee";
            pink = "f4b8e4";
            teal = "81c8be";
          };
          latte = {
            rosewater = "dc8a78";
            base = "eff1f5";
            text = "4c4f69";
            subtext0 = "6c6f85";
            subtext1 = "5c5f77";
            surface1 = "bcc0cc";
            surface2 = "acb0be";
            red = "d20f39";
            green = "40a02b";
            yellow = "df8e1d";
            blue = "1e66f5";
            pink = "ea76cb";
            teal = "179299";
          };
        };

        footColors = flavor: let
          p = palette.${flavor};
        in ''
          foreground=${p.text}
          background=${p.base}
          cursor=${p.base} ${p.rosewater}
          regular0=${p.surface1}
          regular1=${p.red}
          regular2=${p.green}
          regular3=${p.yellow}
          regular4=${p.blue}
          regular5=${p.pink}
          regular6=${p.teal}
          regular7=${p.subtext1}
          bright0=${p.surface2}
          bright1=${p.red}
          bright2=${p.green}
          bright3=${p.yellow}
          bright4=${p.blue}
          bright5=${p.pink}
          bright6=${p.teal}
          bright7=${p.subtext0}
        '';

        vscodeFlavor = flavor:
          if flavor == "frappe"
          then "Frappé"
          else capitalize flavor;

        #? One `case` arm per mode. Every per-mode value is resolved at build
        #? time, so the script body below is identical for dark and light.
        modeCase = mode: let
          flavor = aes.theme.${mode}.flavor;
          footSignal =
            if mode == "dark"
            then "USR1"
            else "USR2";
        in ''
          ${mode})
            kde_scheme=${aes.kdeScheme.${mode}}
            icon=${aes.icons.${mode}}
            gtk_theme=${variables."THEME_GTK_${toUpper mode}"}
            konsole_name=Catppuccin-${capitalize mode}
            vscode_theme='Catppuccin ${vscodeFlavor flavor}'
            foot_signal=${footSignal}
            ;;
        '';

        #? Answer to the old TODO: yes. As a writeShellApplication the tools come
        #? from `runtimeInputs` (no `${pkgs.x}/bin/x` plumbing), shellcheck runs at
        #? build time, and `theme-apply dark|light` works by hand too. Darkman's
        #? scripts become one-line wrappers, so there is one implementation
        #? instead of two near-identical mkScript outputs.
        themeApply = pkgs.writeShellApplication {
          name = "theme-apply";
          runtimeInputs = with pkgs; [
            dbus
            dconf
            gnugrep
            gnused
            procps
            systemd
            kdePackages.kconfig
            kdePackages.plasma-workspace
          ];
          #? Best-effort: one failing step (no Yakuake running, no Plasma) must
          #? not stop the rest, so no errexit/nounset/pipefail.
          bashOptions = [];
          #? SC2046: word-splitting the Yakuake terminal id list is intentional.
          excludeShellChecks = ["SC2046"];
          text = ''
            case "''${1:-}" in
            ${concatMapStringsSep "\n" modeCase modes}
              *)
                echo "usage: theme-apply dark|light" >&2
                exit 2
                ;;
            esac
            mode=$1

            #> Konsole / Yakuake: default profile for new tabs, setProfile for open ones
            kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile "$konsole_name.profile"
            kwriteconfig6 --file yakuakerc --group "Desktop Entry" --key DefaultProfile "$konsole_name.profile"
            for terminal in $(busctl --user call org.kde.yakuake /yakuake/sessions org.kde.yakuake terminalIdList 2>/dev/null | sed 's/^s "//; s/"$//; s/,/ /g'); do
              busctl --user call org.kde.yakuake "/Sessions/$((terminal + 1))" org.kde.konsole.Session setProfile s "$konsole_name" >/dev/null 2>&1 || true
            done

            #> Plasma color scheme: only when a Plasma session is actually running
            if systemctl --user is-active --quiet plasma-plasmashell.service; then
              plasma-apply-colorscheme "$kde_scheme"
            fi

            #> Icons: --notify tells running apps (panel included) the value changed
            kwriteconfig6 --notify --file kdeglobals --group Icons --key Theme "$icon"
            for group in 0 1 2 3 4 5; do
              dbus-send --session --type=signal /KIconLoader org.kde.KIconLoader.iconChanged "int32:$group"
            done

            #> GTK / libadwaita / Electron (also what ghostty follows)
            base=/org/gnome/desktop/interface
            dconf write "$base/color-scheme" "'prefer-$mode'"
            dconf write "$base/gtk-theme" "'$gtk_theme'"
            dconf write "$base/icon-theme" "'$icon'"

            #> foot: USR1 forces the [colors-dark] section, USR2 [colors-light]
            pkill -"$foot_signal" -x foot || true

            #> ghostty follows color-scheme by itself via `theme = dark:...,light:...`.
            #> Only if it does not, uncomment (needs a ghostty that reloads on
            #> SIGUSR2; older ones exit on it, so test with nothing open first):
            # pkill -USR2 -x ghostty || true

            #> VS Code: push the theme into settings.json (Electron does not
            #> re-read the OS scheme reliably at runtime). sed instead of jq
            #> because settings.json is JSONC (comments, trailing commas).
            for dir in ".config/Code/User" ".config/Code - Insiders/User" ".config/VSCodium/User"; do
              settings="$HOME/$dir/settings.json"
              [ -f "$settings" ] || continue
              if grep -q '"workbench.colorTheme"' "$settings"; then
                sed -i -E "s|(\"workbench.colorTheme\"[[:space:]]*:[[:space:]]*)\"[^\"]*\"|\1\"$vscode_theme\"|" "$settings"
              else
                sed -i "0,/{/s|{|{\n  \"workbench.colorTheme\": \"$vscode_theme\",|" "$settings"
              fi
              sed -i -E 's|("window.autoDetectColorScheme"[[:space:]]*:[[:space:]]*)true|\1false|' "$settings"
            done

            #> Panel: deliberately NOT restarting plasmashell (slow). If the panel
            #> ever sticks on the old icons again, add:
            #>   systemctl --user try-restart plasma-plasmashell.service
          '';
        };

        #? Wires `user.keyboard.bindings` (craole.nix: an attrset of ordered
        #? variant-lists per action, e.g. `terminal = [scratchpad primary
        #? secondary]`) into real KDE global shortcuts.
        #?
        #? Mechanism (verified real KDE behaviour, not plasma-manager):
        #?   1. Each binding gets a `~/.local/share/applications/<id>.desktop`
        #?      "Exec=" entry -- this is literally what KDE's own System
        #?      Settings > Shortcuts > "Add Command..." button creates.
        #?   2. `kglobalshortcutsrc` gets one `[<id>.desktop]` group pointing
        #?      the key sequence at that .desktop file.
        #? We write (2) via `kwriteconfig6` in `home.activation` -- the same
        #? tool already used for the theme scripts above -- rather than
        #? `xdg.configFile`, because `kglobalshortcutsrc` is mutated live by
        #? KDE itself; letting home-manager symlink/own the whole file would
        #? either collide or wipe out shortcuts set outside this config.
        #?
        #? Every binding is dispatched through ONE writeShellApplication
        #? (`dots-keybind`) so the mapping from binding -> real command lives
        #? in one place and is testable by hand (`dots-keybind <id>`).
        #?
        #? ASSUMPTIONS TO VERIFY -- the craole.nix binding data names
        #? *what* a shortcut is for, but not always *which app/action*:
        #?   - launcher/terminal/browser/editor variants are guessed from
        #?     the single matching package in `applications.common`
        #?     (vicinae, ghostty, brave, vscode-fhs); `foot` and `hx`
        #?     (helix's binary name) fill the "secondary" slots.
        #?   - `explorer` and `agent` have no matching package anywhere in
        #?     this config, so they dispatch to a notify-send placeholder
        #?     instead of a guessed command.
        #?   - `close`/`lock`/`window`/`workspaceNext`/`workspacePrev` are
        #?     wired via `qdbus6 org.kde.kglobalaccel invokeShortcut
        #?     "<Name>"`, which replays an EXISTING KWin global shortcut by
        #?     name (see kwinActionNames below) rather than reimplementing
        #?     it -- safe if the name is wrong (no-op), but the exact names
        #?     should be checked against `qdbus6 org.kde.kglobalaccel
        #?     org.kde.kglobalaccel.allActionsForComponent kwin` on the
        #?     target machine.
        keybindings = let
          bindings = user.keyboard.bindings or {};

          flattened =
            concatMap
            (action:
              imap0
              (index: variant: variant // {inherit action index;})
              bindings.${action})
            (attrNames bindings);

          id = b: "dots-${b.action}-${toString b.index}";

          qdbusInvoke = actionName: ''qdbus6 org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut "${actionName}"'';

          #? Best-effort KWin default global-shortcut names; verify on target.
          kwinActionNames = {
            "close-0" = "Window Close";
            "close-1" = "Log Out";
            "close-2" = "Shut Down";
            "lock-0" = "Lock Session";
            "lock-1" = "Lock Session";
            "window-0" = "Window Fullscreen";
            "window-1" = "Window Toggle Floating";
            "workspaceNext-0" = "Switch Window Right";
            "workspaceNext-2" = "Switch to Next Desktop";
            "workspacePrev-0" = "Switch Window Left";
            "workspacePrev-2" = "Switch to Previous Desktop";
          };

          notConfigured = b: ''${pkgs.libnotify}/bin/notify-send "Keybind not configured" "${b.description}"'';

          #? action-index -> real shell command. Anything not listed here
          #? falls through to `notConfigured`.
          commands = {
            "launcher-0" = "vicinae toggle";
            "launcher-1" = "vicinae toggle --extension clipboard"; # ASSUMPTION
            "launcher-2" = "vicinae toggle --extension files"; # ASSUMPTION
            "terminal-0" = "ghostty --class=scratchpad --title=scratchpad";
            "terminal-1" = "ghostty";
            "terminal-2" = "foot";
            "browser-0" = "brave --new-window";
            "browser-1" = "brave";
            "browser-2" = "brave --incognito";
            "editor-0" = "code --new-window";
            "editor-1" = "code";
            "editor-2" = "ghostty -e hx";
            "volumeUp-0" = "wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+";
            "volumeUp-1" = "wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 1%+";
            "volumeUp-2" = "wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 15%+";
            "volumeDown-0" = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
            "volumeDown-1" = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-";
            "volumeDown-2" = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 15%-";
            "volumeMute-0" = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            "brightnessUp-0" = "brightnessctl set 5%+";
            "brightnessUp-1" = "brightnessctl set 1%+";
            "brightnessUp-2" = "brightnessctl set 15%+";
            "brightnessDown-0" = "brightnessctl set 5%-";
            "brightnessDown-1" = "brightnessctl set 1%-";
            "brightnessDown-2" = "brightnessctl set 15%-";
          };

          commandFor = b: let
            key = "${b.action}-${toString b.index}";
          in
            if commands ? ${key}
            then commands.${key}
            else if kwinActionNames ? ${key}
            then qdbusInvoke kwinActionNames.${key}
            else notConfigured b;

          keySequence = b:
            concatStringsSep "+" (
              (map (m:
                if m == "SUPER"
                then "Meta"
                else m) (b.modifier or []))
              ++ [b.key]
            );

          dispatcher = pkgs.writeShellApplication {
            name = "dots-keybind";
            runtimeInputs = with pkgs; [
              brave
              brightnessctl
              foot
              ghostty
              helix
              kdePackages.qttools
              libnotify
              vicinae
              vscode-fhs
              wireplumber
            ];
            text = ''
              case "''${1:-}" in
              ${concatMapStringsSep "\n" (b: ''
                  "${id b}")
                    ${commandFor b}
                    ;;
                '')
                flattened}
                *)
                  echo "usage: dots-keybind <id>" >&2
                  exit 2
                  ;;
              esac
            '';
          };
        in {
          desktopEntries = listToAttrs (map (b: {
              name = "applications/${id b}.desktop";
              value.text = ''
                [Desktop Entry]
                Type=Application
                Name=${b.description}
                Exec=${dispatcher}/bin/dots-keybind ${id b}
                NoDisplay=true
              '';
            })
            flattened);

          activation =
            concatMapStringsSep "\n" (b: ''
              ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kglobalshortcutsrc --group "${id b}.desktop" --key "_k_friendly_name" "${b.description}"
              ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kglobalshortcutsrc --group "${id b}.desktop" --key "_launch" "${keySequence b},none,${b.description}"
            '')
            flattened;
        };
      in {
        home = {
          inherit stateVersion;
          username = user.name;
          homeDirectory = user.paths.home;
          #~@ Shell/dev tooling lives in the user's own profile, opted into
          #~@ via `shells`/`coding` in default.nix, rather than system-wide.
          packages = flatten (with packages; (
            forInterface
            ++ (map (app: pkgs.${app}) user.apps)
            ++ (map (env: forShells.${env} or []) user.shells)
            ++ (map (dev: forCoding.${dev} or []) user.coding)
            ++ [themeApply]
          ));

          #? Guarded rather than unconditional: `mapAttrs ... users.normal`
          #? runs for every normal user regardless of desktop, so this stays
          #? a no-op on a host where Plasma (and kglobalshortcutsrc) isn't
          #? actually in use.
          activation.dotsKeybindings = lib.hm.dag.entryAfter ["writeBoundary"] (
            if interface.isPlasma
            then keybindings.activation
            else ""
          );
        };

        programs = {
          vicinae = let
            mkTheme = palette: {
              meta = {
                version = 1;
                inherit (palette) name description variant icon;
                inherits =
                  if palette.variant == "light"
                  then "vicinae-light"
                  else "vicinae-dark";
              };

              colors = with palette; {
                core = {
                  background = base;
                  foreground = text;
                  secondary_background = mantle;
                  border = surface1;
                  accent = blue; # TODO This should come from interface.${mode}.accent
                };
                accents = {
                  inherit blue green yellow;
                  magenta = pink;
                  orange = peach;
                  purple = mauve;
                  red = red;
                  cyan = teal;
                };
              };
            };
          in {
            enable = true;
            extensions = [];
            themes = listToAttrs (
              map (palette: {
                name = palette.slug;
                value = mkTheme palette;
              }) (attrValues palettes)
            );
          };
        };

        services.darkman = {
          enable = true;
          settings = with localization; {
            lat = latitude;
            lng = longitude;
          };
          darkModeScripts.theme = "${themeApply}/bin/theme-apply dark";
          lightModeScripts.theme = "${themeApply}/bin/theme-apply light";
        };

        #? Keybinding launcher .desktop entries (see `keybindings` above),
        #? plus one Konsole profile per mode that theme-apply switches
        #? between.
        xdg.dataFile =
          keybindings.desktopEntries
          // listToAttrs (map (mode: let
              flavor = aes.theme.${mode}.flavor;
            in {
              name = "konsole/Catppuccin-${capitalize mode}.profile";
              value.text = ''
                [Appearance]
                ColorScheme=Catppuccin-${capitalize flavor}
                Font=Maple Mono NF,18

                [General]
                Name=Catppuccin-${capitalize mode}
                Parent=FALLBACK/

                [Interaction Options]
                AutoCopySelectedText=true
              '';
            })
            modes);

        #? foot needs explicit palettes; ghostty ships Catppuccin themes.
        #? If you already have these files (e.g. from your dots repo), merge
        #? the theme parts into them instead: home-manager refuses to clobber.
        xdg.configFile = {
          "foot/foot.ini".text = ''
            [colors-dark]
            ${footColors aes.theme.dark.flavor}
            [colors-light]
            ${footColors aes.theme.light.flavor}
          '';

          "ghostty/config".text = ''
            theme = dark:Catppuccin ${capitalize aes.theme.dark.flavor},light:Catppuccin ${capitalize aes.theme.light.flavor}
          '';
        };
      })
      users.normal;
  };
}
