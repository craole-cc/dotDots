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

        inherit (lib.strings) toUpper;
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

        prefix = toUpper name;

        ref = var: "$" + prefix + "_" + var;

        cfg = {
          ytd = ref "CFG_YTD";
          mpv = ref "CFG_MPV";
          mpd = ref "CFG_MPD";
        };

        tmpl = {
          ytd = ref "CFG_YTD";
          mpv = ref "CFG_MPV";
          mpd = ref "CFG_MPD";
        };

        music = ref "MUSIC";
      in {
        devShells.default = pkgs.mkShell {
          inherit env;

          packages =
            [
              (pkgs.substituteAll {
                name = "mpd";
                src = paths.bin + "/mpd";
                isExecutable = true;
                cmd = "${pkgs.mpd}";
              })

              (pkgs.substituteAll rec {
                name = "mpv";
                src = paths.bin + "/mpv";
                isExecutable = true;
                cmd = "${pkgs.mpv}";
                mpv = cmd;
              })

              (pkgs.substituteAll {
                name = "ytd";
                src = paths.bin + "/ytd";
                isExecutable = true;
                cmd = "${pkgs.yt-dlp}";
              })
            ]
            ++ (with pkgs; [
              feh
              imv
              swww

              ncmpcpp
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
            ]);

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

            export ${prefix}_ROOT="''${APP_ROOT}"
            export ${prefix}_CFG_BASE="''${APP_CFG_BASE}"
            export ${prefix}_CFG_YTD="''${APP_CFG_YTD}"
            export ${prefix}_CFG_MPV="''${APP_CFG_MPV}"
            export ${prefix}_CFG_MPD="''${APP_CFG_MPD}"
            export ${prefix}_DOWNLOADS="''${APP_DOWNLOADS}"
            export ${prefix}_MUSIC="''${APP_MUSIC}"
            export ${prefix}_PICTURES="''${APP_PICTURES}"
            export ${prefix}_VIDEOS="''${APP_VIDEOS}"

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
