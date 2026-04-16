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
        prefix = lib.strings.toUpper name;

        packages =
          [
            (pkgs.substituteAll {
              isExecutable = true;
              src = paths.build.modules.ytd + "/cmd.sh";
              command = "${pkgs.yt-dlp}/bin/yt-dlp";
              format = "1080p";
              config = toString paths.runtime.cfg.ytd;
              settings = toString (paths.build.modules.ytd + "/settings.conf");
              downloads = toString paths.runtime.downloads;
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
          inherit (paths.build.modules) ytd mpv mpd;
          inherit (paths.runtime) root cfg downloads music pictures videos;
        in {
          "${prefix}" = toString root;
          "${prefix}_MOD_YTD" = toString ytd;
          "${prefix}_MOD_MPD" = toString mpd;
          "${prefix}_MOD_MPV" = toString mpv;
          "${prefix}_CFG_BASE" = toString cfg.base;
          "${prefix}_CFG_YTD" = toString cfg.ytd;
          "${prefix}_CFG_MPV" = toString cfg.mpv;
          "${prefix}_CFG_MPD" = toString cfg.mpd;
          "${prefix}_DOWNLOADS" = toString downloads;
          "${prefix}_MUSIC" = toString music;
          "${prefix}_PICTURES" = toString pictures;
          "${prefix}_VIDEOS" = toString videos;
        };

        shellHook = let
          prefix = lib.strings.toUpper name;
          ytd = {
            mod = "$" + prefix + "_MOD_YTD";
            cfg = "$" + prefix + "_CFG_YTD";
          };
          mpd = {
            mod = "$" + prefix + "_MOD_MPD";
            cfg = "$" + prefix + "_CFG_MPD";
          };
          mpv = {
            mod = "$" + prefix + "_MOD_MPV";
            cfg = "$" + prefix + "_CFG_MPV";
          };
          music = "$" + prefix + "_MUSIC";
        in ''
          printf "%s\n\n" "${description}"

          #> Deploy scripts
          if [ ! -f "${ytd.cfg}/settings.conf" ]; then
            mkdir -p "$(dirname "${ytd.cfg}")"
            cp "${ytd.mod}/settings.conf" "${ytd.cfg}/settings.conf"
          fi

          if [ ! -f "${mpd.cfg}/settings.conf" ]; then
            mkdir -p "$(dirname "${mpd.cfg}")"
            cp "${mpd.mod}/settings.conf" "${mpd.cfg}/settings.conf"
          fi

          if [ ! -f "${mpv.cfg}/settings.conf" ]; then
            mkdir -p "$(dirname "${mpv.cfg}")"
            cp "${mpv.mod}/settings.conf" "${mpv.cfg}/settings.conf"
          fi

          if [ ! -f "${mpv.cfg}/input.conf" ]; then
            cp "${mpv.mod}/input.conf" "${mpv.cfg}/input.conf"
          fi


          #> Show the usage guide
          printf "Video Tools:\n"
          printf "  mpv         - Enhanced MPV with custom config\n"
          printf "  ytd         - Download videos (usage: yt-download <url> [quality])\n\n"

          printf "Image Viewers:\n"
          printf "  feh         - Light image viewer\n"
          printf "  imv         - Alternative image viewer\n\n"

          printf "Music & Radio:\n"
          printf "  ncmpcpp     - Music player (music dir: "${music}")\n"
          printf "  curseradio  - Terminal radio\n\n"
        '';
      in {
        devShells.default = pkgs.mkShell {
          inherit packages env shellHook;
        };
      }
    );
}
