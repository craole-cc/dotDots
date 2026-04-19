{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs @ {...}:
    inputs.flake-utils.lib.eachDefaultSystem (
      system: let
        src = import ./. {inherit inputs system;};
        inherit (src) name description lib paths pkgs;
        inherit (src.environment) build runtime;
        inherit (lib.attrsets) attrValues listToAttrs;
        inherit (lib.lists) concatMap;

        #> Substitute @cmd@ in each bin script with real store paths
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
              scriptPath = paths.bin.mpv;
              cmd = "${pkgs.mpv}/bin/mpv";
              extraSubstitutions = {cfgVar = environment.vars.mpvCfg;};
            })))
            (pkgs.writeShellScriptBin "mpd" (builtins.readFile (mkScript {
              scriptPath = paths.bin.mpd;
              cmd = "${pkgs.mpd}/bin/mpd";
              extraSubstitutions = {
                cfgVar = environment.vars.mpdCfg;
                musicVar = environment.vars.music;
              };
            })))
            (pkgs.writeShellScriptBin "ytd" (builtins.readFile (mkScript {
              scriptPath = paths.bin.ytd;
              cmd = "${pkgs.yt-dlp}/bin/yt-dlp";
              extraSubstitutions = {
                cfgVar = environment.vars.ytdCfg;
                downloadsVar = environment.vars.downloads;
              };
            })))
          ];
        };

        #> Substitute @ytdlp@ in mpv settings.conf
        mpvCfg = pkgs.substituteAll {
          src = "${paths.cfg.mpv}/settings.conf";
          ytdlp = pkgs.yt-dlp;
        };

        #> Recursively collect all { var, val } leaves from nested env
        isLeaf = v: v ? var && v ? val;
        collectLeaves = v:
          if isLeaf v
          then [v]
          else concatMap collectLeaves (attrValues v);

        #> Convert to { VAR_NAME = /path; } for mkShell
        env = listToAttrs (
          map ({
            var,
            val,
          }: {
            name = var;
            value = toString val;
          })
          (collectLeaves src.env)
        );
      in {
        devShells.default = pkgs.mkShell {
          inherit env;

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
            #> Override cfg vars to writable runtime locations
            ${runtime.mpd.var}=${runtime.mpd.val}
            ${runtime.mpv.var}=${runtime.mpv.val}
            ${runtime.ytd.var}=${runtime.ytd.val}
            export \
              ${runtime.mpd.var} \
              ${runtime.mpv.var} \
              ${runtime.ytd.var}

            #> Override user dir vars to actual $HOME paths
            ${runtime.downloads.var}=${runtime.downloads.val}
            ${runtime.music.var}=${runtime.music.val}
            ${runtime.pictures.var}=${runtime.pictures.val}
            ${runtime.videos.var}=${runtime.videos.val}
            export \
              ${runtime.downloads.var} \
              ${runtime.music.var} \
              ${runtime.pictures.var} \
              ${runtime.videos.var}

            #> Create dirs
            mkdir -p \
              ${runtime.mpd.val} \
              ${runtime.mpv.val} \
              ${runtime.ytd.val} \
              ${runtime.downloads.val} \
              ${runtime.music.val} \
              ${runtime.pictures.val} \
              ${runtime.videos.val}

            #> Copy config templates (skip if already customized)
            # [[ -f "${runtime.mpd.val}/mpd.conf" ]] ||
            #   cp ${build.mpd.val}/settings.conf "${runtime.mpd.val}/mpd.conf"
            # [[ -f "${runtime.mpv.val}/settings.conf" ]] ||
            #   cp ${build.mpv.val}/settings.conf "${runtime.mpv.val}/mpv.conf"
            # [[ -f "${runtime.mpv.val}/input.conf" ]] ||
            #   cp ${build.mpv.val}/input.conf "${runtime.mpv.val}/input.conf"
            # [[ -f "${runtime.ytd.val}/settings.conf" ]] ||
            #   cp ${build.ytd.val}/settings.conf "${runtime.ytd.val}/yt-dlp.conf"

            #> Display help
            printf "%s\n\n" "${description}"

            printf "Video Tools:\n"
            printf "  mpv  - Enhanced MPV with custom config\n"
            printf "  ytd  - Download videos (usage: ytd <url> [quality])\n\n"

            printf "Image Viewers:\n"
            printf "  feh  - Light image viewer\n"
            printf "  imv  - Alternative image viewer\n\n"

            printf "Music & Radio:\n"
            printf "  ncmpcpp  - Music player (dir: %s)\n" "$MEDIA_MUSIC"
            printf "  mpd      - Music daemon\n"
            printf "  curseradio - Terminal radio\n\n"
          '';
        };
      }
    );
}
