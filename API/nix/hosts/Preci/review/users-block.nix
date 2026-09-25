    users =
      mapAttrs (name: user: let
        aes = aesthetics.users.${name};
        modes = ["dark" "light"];

        #? Catppuccin colours for terminals that need an explicit palette (foot).
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
      in {
        home = {
          inherit stateVersion;
          username = user.name;
          homeDirectory = user.paths.home;
          #~@ Shell/dev tooling lives in the user's own profile, opted into
          #~@ via `shells`/`coding` in default.nix, rather than system-wide.
          packages = flatten (with packages; (
            forInterface
            ++ (map (app: pkgs.${app}) (user.apps or []))
            ++ (map (env: forShells.${env} or []) user.shells)
            ++ (map (dev: forCoding.${dev} or []) (user.coding or []))
            ++ [themeApply]
          ));
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

        #? Konsole profiles (one per mode) that theme-apply switches between.
        xdg.dataFile = listToAttrs (map (mode: let
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
        }) modes);

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
