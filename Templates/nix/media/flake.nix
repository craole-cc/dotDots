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

            printf "Video Tools:\n"
            printf "  mpv         - Enhanced MPV with custom config\n"
            printf "  ytd         - Download videos (usage: ytd <url> [quality])\n"
            printf "  yt-dlp      - Direct yt-dlp (bypasses shell issues)\n\n"

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
