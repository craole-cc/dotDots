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
        inherit (src.env) build;
        inherit (lib.attrsets) attrValues listToAttrs;

        env = listToAttrs (
          map ({
            var,
            val,
          }: {
            name = var;
            value = val;
          }) (attrValues build)
        );
      in {
        devShells.default = pkgs.mkShell {
          inherit env;

          packages = with pkgs; [
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
          ];

          shellHook = ''
            printf "%s\n\n" "${description}"

            export APP_ROOT="''${HOME}/${name}"
            export APP_CFG_BASE="''${APP_ROOT}/.config"
            export APP_CFG_YTD="''${APP_CFG_BASE}/ytd"
            export APP_CFG_MPV="''${APP_CFG_BASE}/mpv"
            export APP_CFG_MPD="''${APP_CFG_BASE}/mpd"
            export APP_DOWNLOADS="''${APP_ROOT}/Downloads"
            export APP_MUSIC="''${APP_ROOT}/Music"
            export APP_PICTURES="''${APP_ROOT}/Pictures"
            export APP_VIDEOS="''${APP_ROOT}/Videos"

            mkdir -p \
              "''${APP_CFG_YTD}" \
              "''${APP_CFG_MPV}" \
              "''${APP_CFG_MPD}" \
              "''${APP_DOWNLOADS}" \
              "''${APP_MUSIC}" \
              "''${APP_PICTURES}" \
              "''${APP_VIDEOS}"

            if [ ! -f "''${APP_CFG_MPD}/mpd.conf" ]; then
              cp "${build.mpd.val}/settings.conf" "''${APP_CFG_MPD}/mpd.conf"
            fi

            if [ ! -f "''${APP_CFG_MPV}/mpv.conf" ]; then
              cp "${build.mpv.val}/settings.conf" "''${APP_CFG_MPV}/mpv.conf"
            fi

            if [ ! -f "''${APP_CFG_MPV}/input.conf" ]; then
              cp "${build.mpv.val}/input.conf" "''${APP_CFG_MPV}/input.conf"
            fi

            if [ ! -f "''${APP_CFG_YTD}/yt-dlp.conf" ]; then
              cp "${build.ytd.val}/settings.conf" "''${APP_CFG_YTD}/yt-dlp.conf"
            fi

            export APP_WRAPPER_BIN="''${APP_ROOT}/.bin"
            mkdir -p "''${APP_WRAPPER_BIN}"

            install -m755 "${paths.bin}/mpd" "''${APP_WRAPPER_BIN}/mpd"
            install -m755 "${paths.bin}/mpv" "''${APP_WRAPPER_BIN}/mpv"
            install -m755 "${paths.bin}/ytd" "''${APP_WRAPPER_BIN}/ytd"

            substituteInPlace "''${APP_WRAPPER_BIN}/mpd" \
              --subst-var-by cmd "${pkgs.mpd}/bin/mpd"

            substituteInPlace "''${APP_WRAPPER_BIN}/mpv" \
              --subst-var-by cmd "${pkgs.mpv}/bin/mpv" \
              --subst-var-by mpv "${pkgs.mpv}"

            substituteInPlace "''${APP_WRAPPER_BIN}/ytd" \
              --subst-var-by cmd "${pkgs.yt-dlp}/bin/yt-dlp"

            export PATH="''${APP_WRAPPER_BIN}:$PATH"

            printf "Video Tools:\n"
            printf "  mpv         - Enhanced MPV with custom config\n"
            printf "  ytd         - Download videos (usage: ytd <url> [quality])\n\n"

            printf "Image Viewers:\n"
            printf "  feh         - Light image viewer\n"
            printf "  imv         - Alternative image viewer\n\n"

            printf "Music & Radio:\n"
            printf "  ncmpcpp     - Music player (music dir: %s)\n" "''${APP_MUSIC}"
            printf "  curseradio  - Terminal radio\n\n"
          '';
        };
      }
    );
}
