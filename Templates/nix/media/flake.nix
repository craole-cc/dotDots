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
        inherit (src.env) build mkRuntimeSetup;
        inherit (lib.strings) toUpper;
        inherit (lib.attrsets) attrValues listToAttrs;

        # Flatten {var, val} records → {VAR = val} attrset for mkShell.
        env = listToAttrs (map ({
          var,
          val,
        }: {
          name = var;
          value = val;
        }) (attrValues build));

        # Derive shell variable reference strings from the project prefix so
        # the shellHook isn't hardcoded to "MEDIA_*".
        prefix = toUpper name;
        ref = var: "$" + prefix + "_" + var;
        ytd = {
          bin = ref "BIN_YTD";
          cfg = ref "CFG_YTD";
        };
        mpd = {
          bin = ref "BIN_MPD";
          cfg = ref "CFG_MPD";
        };
        mpv = {
          bin = ref "BIN_MPV";
          cfg = ref "CFG_MPV";
        };
        music = ref "MUSIC";
        # pictures = ref "PICTURES";
        # videos = ref "VIDEOS";

        packages =
          [
            (pkgs.substituteAll {
              name = "mpd";
              src = paths.build.bin + "/mpd";
              isExecutable = true;
              cmd = "${pkgs.mpd}";
              scripts = toString paths.build.bin;
            })
            (pkgs.substituteAll rec {
              name = "mpv";
              src = paths.build.bin + "/mpv";
              isExecutable = true;
              cmd = "${pkgs.mpv}";
              scripts = toString paths.build.bin;
              mpv = cmd; #? for ytdl_hook path
            })
            (pkgs.substituteAll {
              name = "ytd";
              src = paths.build.bin + "/ytd";
              isExecutable = true;
              cmd = "${pkgs.yt-dlp}";
              scripts = toString paths.build.bin;
            })
          ]
          ++ (with pkgs; [
            #| Image
            feh
            imv
            swww

            #| Music
            ncmpcpp
            # mpc-cli
            # mpd
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
            yt-dlp
          ]);

        shellHook = ''
          printf "%s\n\n" "${description}"

          ${mkRuntimeSetup}
          setup_${name}_runtime

          #> Deploy configs
          if [ ! -f "${mpd.cfg}/settings.conf" ]; then
            mkdir -p "${mpd.cfg}"
            cp "${mpd.bin}/settings.conf" "${mpd.cfg}/settings.conf"
          fi
          if [ ! -f "${mpv.cfg}/settings.conf" ]; then
            mkdir -p "${mpv.cfg}"
            cp "${mpv.bin}/settings.conf" "${mpv.cfg}/settings.conf"
          fi
          if [ ! -f "${mpv.cfg}/input.conf" ]; then
            cp "${mpv.bin}/input.conf" "${mpv.cfg}/input.conf"
          fi
          if [ ! -f "${ytd.cfg}/settings.conf" ]; then
            mkdir -p "${ytd.cfg}"
            cp "${ytd.bin}/settings.conf" "${ytd.cfg}/yt-dlp.conf"
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
