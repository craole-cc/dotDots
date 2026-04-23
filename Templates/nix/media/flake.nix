{
  inputs = {
    nixurl = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system: let
        src = import ./. {inherit inputs system;};
        inherit (src) name lib paths pkgs description;
        inherit (lib.strings) readFile;
        inherit (pkgs) substituteAll symlinkJoin writeShellScriptBin;

        e = src.env;

        #> Build-time script substitution — @cmd@ and var name placeholders
        mkScript = {
          scriptPath,
          cmd,
          extraSubstitutions ? {},
        }:
          substituteAll ({
              src = scriptPath;
              inherit cmd;
              isExecutable = true;
            }
            // extraSubstitutions);

        scripts = symlinkJoin {
          name = "${name}-scripts";
          paths = [
            (writeShellScriptBin "mpv" (readFile (mkScript {
              scriptPath = paths.bin.mpv.store;
              cmd = "${pkgs.mpv}/bin/mpv";
              extraSubstitutions = {cfgVar = e.mpv.cfg.var;};
            })))
            (writeShellScriptBin "mpd" (readFile (mkScript {
              scriptPath = paths.bin.mpd.store;
              cmd = "${pkgs.mpd}/bin/mpd";
              extraSubstitutions = {
                cfgVar = e.mpd.cfg.var;
                musicVar = e.music.var;
              };
            })))
            (writeShellScriptBin "ytd" (readFile (mkScript {
              scriptPath = paths.bin.ytd.store;
              cmd = "${pkgs.yt-dlp}/bin/yt-dlp";
              extraSubstitutions = {
                cfgVar = e.ytd.cfg.var;
                downloadsVar = e.downloads.var;
              };
            })))
          ];
        };

        #> Substitute @ytdlp@ in mpv settings.conf at build time
        mpvSettings = substituteAll {
          src = "${paths.cfg.mpv.store}/settings.conf";
          ytdlp = pkgs.yt-dlp;
        };
        #> Flatten nested { var, val } leaves -> { VAR = "val"; } for mkShell
      in {
        devShells.default = pkgs.mkShell {
          # env = listToAttrs (
          #   map ({
          #     var,
          #     val,
          #   }: {
          #     name = var;
          #     value = toString val;
          #   })
          #   (collectLeaves e.store)
          # );
          # env = {
          #   # ${e.mpv.cfg.var} = e.mpv.cfg.val;
          #   pop = "lol";
          # };

          packages =
            (with pkgs; [
              bash
              btop
              curl
              curseradio
              feh
              ffmpeg
              freetube
              fzf
              imv
              jq
              libnotify
              mediainfo
              mpc-cli
              mpd
              mpvc
              ncmpcpp
              noto-fonts-emoji
              pamixer
              playerctl
              rlwrap
              shortwave
              socat
              strawberry
              swww
              xclip
              yt-dlp
            ])
            ++ [scripts];

          shellHook = ''
            #> Runtime paths — $HOME expands here correctly
            export ${e.mpv.cfg.var}="${e.mpv.cfg.val}"
            export ${e.mpd.cfg.var}="${e.mpd.cfg.val}"
            export ${e.ytd.cfg.var}="${e.ytd.cfg.val}"
            export ${e.music.var}="${e.music.val}"
            export ${e.videos.var}="${e.videos.val}"
            export ${e.pictures.var}="${e.pictures.val}"
            export ${e.downloads.var}="${e.downloads.val}"

            #> Create them if missing
            mkdir -p \
              "${e.mpv.cfg.val}" \
              "${e.mpd.cfg.val}" \
              "${e.ytd.cfg.val}" \
              "${e.music.val}"   \
              "${e.videos.val}"  \
              "${e.pictures.val}"\
              "${e.downloads.val}"

            #> Deploy configs into namespaced dirs (first run only)
            [[ -d "${e.mpv.cfg.val}" ]] || {
              mkdir -p "${e.mpv.cfg.val}"
              cp --no-preserve=mode ${mpvSettings} "${e.mpv.cfg.val}/mpv.conf"
              cp --no-preserve=mode ${paths.cfg.mpv.store}/input.conf "${e.mpv.cfg.val}/input.conf"
            }
            [[ -d "${e.mpd.cfg.val}" ]] || {
              mkdir -p "${e.mpd.cfg.val}"
              cp --no-preserve=mode ${paths.cfg.mpd.store}/settings.conf "${e.mpd.cfg.val}/mpd.conf"
            }
            [[ -d "${e.ytd.cfg.val}" ]] || {
              mkdir -p "${e.ytd.cfg.val}"
              cp --no-preserve=mode ${paths.cfg.ytd.store}/settings.conf "${e.ytd.cfg.val}/yt-dlp.conf"
            }

            #> ble.sh compatibility
            ncmpcpp() {
              declare -f ble-detach &>/dev/null && ble-detach
              command ncmpcpp "$@"
              declare -f ble-attach &>/dev/null && ble-attach
            }
            mpv() {
              declare -f ble-detach &>/dev/null && ble-detach
              command mpv "$@"
              local rc=$?
              wait
              declare -f ble-attach &>/dev/null && ble-attach
              return $rc
            }
            ytd() {
              declare -f ble-detach &>/dev/null && ble-attach
              command ytd "$@"
              local rc=$?
              wait
              declare -f ble-attach &>/dev/null && ble-attach
              return $rc
            }

            printf "%s\n\n" "${description}"
            printf "Video Tools:\n"
            printf "  mpv  - Enhanced MPV with custom config\n"
            printf "  ytd  - Download videos (usage: ytd <url> [quality])\n\n"
            printf "Image Viewers:\n"
            printf "  feh  - Light image viewer\n"
            printf "  imv  - Alternative image viewer\n\n"
            printf "Music & Radio:\n"
            printf "  ncmpcpp     - Music player (dir: %s)\n" "${e.music.val}"
            printf "  mpd         - Music daemon\n"
            printf "  curseradio  - Terminal radio\n\n"
          '';
        };
      }
    );
}
