{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs @ {...}: let
  in
    inputs.flake-utils.lib.eachDefaultSystem (
      system: let
        src = import ./. {inherit inputs system;};
        inherit (src) name lib paths pkgs description;

        packages =
          [
            (pkgs.substituteAll {
              isExecutable = true;
              src = paths.build.modules.ytd + "/cmd.sh";
              cmd = "${pkgs.yt-dlp}/bin/yt-dlp";
              fmt = "1080p";
            })
          ]
          ++ (with pkgs; [
            #| Image
            feh
            imv
            swww

            #| Music
            ncmpcpp
            mpc-cli
            mpd
            curseradio
            playerctl
            pamixer
            # tauon
            shortwave
            strawberry
            # deadbeef

            #| Utilities
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

            #| Video
            freetube
            # mpvEnhanced
            mpvc
            # yt-dlp
          ]);

        env = let
          prefix = lib.strings.toUpper name;
          inherit (paths.runtime) bin cfg downloads music pictures videos;
        in {
          "${prefix}" = paths.runtime.root;
          "${prefix}_BIN_BASE" = bin.base;
          "${prefix}_BIN_YTD" = bin.ytd;
          "${prefix}_BIN_MPV" = bin.mpv;
          "${prefix}_CFG_BASE" = cfg.base;
          "${prefix}_CFG_YTD" = cfg.ytd;
          "${prefix}_CFG_MPV" = cfg.mpv;
          "${prefix}_CFG_MPD" = cfg.mpd;
          "${prefix}_DOWNLOADS" = downloads;
          "${prefix}_MUSIC" = music;
          "${prefix}_PICTURES" = pictures;
          "${prefix}_VIDEOS" = videos;
        };

        shellHook = let
          inherit (paths.runtime) bin cfg downloads music pictures videos;
          inherit (paths.binaries) modules;
        in ''
          printf "%s\n\n" "${description}"

          #> Ensure essential directories exist
          mkdir -p \
            "${bin.base}" \
            "${cfg.ytd}" \
            "${cfg.mpv}" \
            "${cfg.mpd}" \
            "${downloads}" \
            "${music}" \
            "${pictures}" \
            "${videos}"

          #> Deploy scripts
            if [ ! -f "$MEDIA_CFG_YTD/settings.conf" ]; then
              cp \
                "${modules.ytd}/settings.conf" \
                "$MEDIA_CFG_YTD/settings.conf"
            fi
            if [ ! -f "$MEDIA_CFG_MPD/settings.conf" ]; then
              cp \
                "${modules.mpd}/settings.conf" \
                "$MEDIA_CFG_MPD/settings.conf"
            fi
            if [ ! -f "$MEDIA_CFG_MPV/settings.conf" ]; then
              cp \
                "${modules.mpv}/settings.conf" \
                "$MEDIA_CFG_MPV/settings.conf"
            fi
            if [ ! -f "$MEDIA_CFG_MPV/input.conf" ]; then
              cp \
                "${modules.mpv}/input.conf" \
                "$MEDIA_CFG_MPV/input.conf"
            fi

          #> Show the usage guide
          printf "Video Tools:\n"
          printf "  mpv         - Enhanced MPV with custom config\n"
          printf "  ytd         - Download videos (usage: yt-download <url> [quality])\n\n"

          printf "Image Viewers:\n"
          printf "  feh         - Light image viewer\n"
          printf "  imv         - Alternative image viewer\n\n"

          printf "Music & Radio:\n"
          printf "  ncmpcpp     - Music player (music dir: ${music})\n"
          printf "  curseradio  - Terminal radio\n\n"
        '';
      in {
        devShells.default = pkgs.mkShell {
          inherit packages env shellHook;
        };
      }
    );
}
