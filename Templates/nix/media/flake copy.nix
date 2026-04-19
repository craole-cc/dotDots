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

        #> Substitute @cmd@ in each bin script with real store paths
        mkScript = {
          scriptPath,
          cmd,
          extraSubstitutions ? {},
        }:
          pkgs.substituteAll (
            {
              src = scriptPath;
              inherit cmd;
              isExecutable = true;
            }
            // extraSubstitutions
          );

        scripts = pkgs.symlinkJoin {
          name = "${name}-scripts";
          paths = [
            (pkgs.writeShellScriptBin "ytd" (builtins.readFile (mkScript {
              scriptPath = paths.bin.ytd;
              cmd = "${pkgs.yt-dlp}/bin/yt-dlp";
            })))
            (pkgs.writeShellScriptBin "mpv" (builtins.readFile (mkScript {
              scriptPath = paths.bin.mpv;
              cmd = "${pkgs.mpv}/bin/mpv";
            })))
            (pkgs.writeShellScriptBin "mpd" (builtins.readFile (mkScript {
              scriptPath = paths.bin.mpd;
              cmd = "${pkgs.mpd}/bin/mpd";
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
              ...
            ]);

          shellHook = ''
            #> Resolve and create user dirs
            MEDIA_MUSIC="$HOME/Music"
            MEDIA_VIDEOS="$HOME/Videos"
            MEDIA_PICTURES="$HOME/Pictures"
            MEDIA_DOWNLOADS="$HOME/Downloads"
            export MEDIA_MUSIC MEDIA_VIDEOS MEDIA_PICTURES MEDIA_DOWNLOADS
            mkdir -p "$MEDIA_MUSIC" "$MEDIA_VIDEOS" "$MEDIA_PICTURES" "$MEDIA_DOWNLOADS"

            #> Copy substituted mpv config into place
            mkdir -p "$MEDIA_CFG_MPV"
            cp --no-preserve=mode ${mpvCfg} "$MEDIA_CFG_MPV/mpv.conf"
            cp --no-preserve=mode ${paths.cfg.mpv}/input.conf "$MEDIA_CFG_MPV/input.conf"

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
