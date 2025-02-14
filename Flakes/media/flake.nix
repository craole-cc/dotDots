# flake.nix
{
  description = "Comprehensive media environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) substituteAll mkShell;

        mpdConfig = substituteAll {
          src = ./modules/mpd.conf;
        };

        mpvConfig = substituteAll {
          src = ./modules/mpv.conf;
          yt-dlp = pkgs.yt-dlp;
        };

        mpvScript = substituteAll {
          src = ./modules/mpv.sh;
          isExecutable = true;
          mpv = pkgs.mpv;
        };

        ytdScript = substituteAll {
          src = ./modules/ytd.sh;
          isExecutable = true;
          yt-dlp = pkgs.yt-dlp;
        };
      in {
        devShells.default = mkShell {
          buildInputs = with pkgs; [
            #| Video tools
            mpv
            yt-dlp
            ffmpeg

            #| Image viewers
            feh
            imv

            #| Music and radio
            ncmpcpp
            mpc-cli
            mpd
            curseradio
            playerctl
            pamixer

            #| Additional utilities
            xclip
            socat
            jq
            mediainfo
          ];

          shellHook = ''
            printf "🎬 Comprehensive Media Environment Loaded!\n\n"

            #@ Set up directory structure
            mkdir -p {bin,config/{mpv/scripts,mpd/playlists},music,videos}

            #@ Copy and process config files
            cp ${mpvScript} bin/mpv
            cp ${ytdScript} bin/ytd
            cp ${mpvConfig} config/mpv/mpv.conf
            cp ${mpdConfig} config/mpd/mpd.conf

            #@ Set up executable scripts
            chmod +x bin/*
            PATH="$PATH:$PWD/bin"
            export PATH
            alias radio='curseradio'

            printf "Video Tools:\n"
            printf "  mpv       - Enhanced MPV with custom config\n"
            printf "  ytd       - Download videos (usage: ytd <url> [quality])\n\n"

            printf "Image Viewers:\n"
            printf "  feh       - Light image viewer\n"
            printf "  imv       - Alternative image viewer\n\n"

            printf "Music & Radio:\n"
            printf "  ncmpcpp   - Music player (music dir: music)\n"
            printf "  radio     - Terminal radio\n\n"
          '';
        };
      }
    );
}
