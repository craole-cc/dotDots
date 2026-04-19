{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs @ {...}:
    inputs.flake-utils.lib.eachDefaultSystem (
      system: let
        src = import ./. {inherit inputs system;};
        inherit (src) name lib paths pkgs description;
        inherit (lib.attrsets) attrValues listToAttrs;
        inherit (lib.lists) concatMap;

        e = src.env;

        #> Build-time script substitution — @cmd@ and var name placeholders
        mkScript = {
          scriptPath,
          cmd,
          extraSubstitutions ? {},
        }:
          pkgs.substituteAll ({
              src = scriptPath;
              inherit cmd;
              isExecutable = true;
            }
            // extraSubstitutions);

        scripts = pkgs.symlinkJoin {
          name = "${name}-scripts";
          paths = [
            (pkgs.writeShellScriptBin "mpv" (builtins.readFile (mkScript {
              scriptPath = paths.bin.mpv.store;
              cmd = "${pkgs.mpv}/bin/mpv";
              extraSubstitutions = {cfgVar = e.mpv.cfg.var;};
            })))
            (pkgs.writeShellScriptBin "mpd" (builtins.readFile (mkScript {
              scriptPath = paths.bin.mpd.store;
              cmd = "${pkgs.mpd}/bin/mpd";
              extraSubstitutions = {
                cfgVar = e.mpd.cfg.var;
                musicVar = e.music.var;
              };
            })))
            (pkgs.writeShellScriptBin "ytd" (builtins.readFile (mkScript {
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
        mpvSettings = pkgs.substituteAll {
          src = paths.cfg.mpv.store + "/settings.conf";
          ytdlp = pkgs.yt-dlp;
        };

        #> Flatten nested { var, val } leaves -> { VAR = "val"; } for mkShell
        isLeaf = v: v ? var && v ? val;
        collectLeaves = v:
          if isLeaf v
          then [v]
          else concatMap collectLeaves (attrValues v);
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

          packages =
            [scripts]
            ++ (with pkgs; [
              feh
              imv
              swww
              ncmpcpp
              mpc-cli
              mpd
              curseradio
              playerctl
              pamixer
              shortwave
              strawberry
              btop
              ffmpeg
              curl
              fzf
              jq
              libnotify
              mediainfo
              rlwrap
              socat
              xclip
              freetube
              mpvc
              yt-dlp
              bash
            ]);

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

            #> Always sync config templates (preserves user edits via git)
            cp --no-preserve=mode ${mpvSettings}                       "${e.mpv.cfg.val}/mpv.conf"
            cp --no-preserve=mode ${paths.cfg.mpv.store}/input.conf    "${e.mpv.cfg.val}/input.conf"
            cp --no-preserve=mode ${paths.cfg.mpd.store}/settings.conf "${e.mpd.cfg.val}/mpd.conf"
            cp --no-preserve=mode ${paths.cfg.ytd.store}/settings.conf "${e.ytd.cfg.val}/yt-dlp.conf"
            # [[ -f "${e.mpv.cfg.val}/mpv.conf" ]] ||
            #   cp --no-preserve=mode \
            #     ${mpvSettings} "${e.mpv.cfg.val}/mpv.conf"
            # [[ -f "${e.mpv.cfg.val}/input.conf" ]] ||
            #   cp --no-preserve=mode \
            #     ${paths.cfg.mpv.store}/input.conf "${e.mpv.cfg.val}/input.conf"
            # [[ -f "${e.mpd.cfg.val}/mpd.conf" ]] ||
            #   cp --no-preserve=mode \
            #     ${paths.cfg.mpd.store}/settings.conf "${e.mpd.cfg.val}/mpd.conf"
            # [[ -f "${e.ytd.cfg.val}/yt-dlp.conf" ]] ||
            #   cp --no-preserve=mode \
            #     ${paths.cfg.ytd.store}/settings.conf "${e.ytd.cfg.val}/yt-dlp.conf"

            #> ble.sh compatibility
            ncmpcpp() {
              declare -f ble-detach &>/dev/null && ble-detach
              command ncmpcpp "$@"
              declare -f ble-attach &>/dev/null && ble-attach
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
