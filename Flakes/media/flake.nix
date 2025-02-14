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
          ytdlp = pkgs.yt-dlp;
        };

        mpvScript = substituteAll {
          src = ./modules/mpv.sh;
          isExecutable = true;
          mpv = pkgs.mpv;
        };

        ytdScript = substituteAll {
          src = ./modules/ytd.sh;
          isExecutable = true;
          ytdlp = pkgs.yt-dlp;
        };

        initScript = substituteAll {
          src = ./modules/init.sh;
          isExecutable = true;
          ytdlp = pkgs.yt-dlp;
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
            cp ${mpvScript} ./bin/mpv
            cp ${ytdScript} ./bin/ytd
            cp ${initScript} ./bin/media-init
            cp ${mpvConfig} ./config/mpv/mpv.conf
            cp ${mpdConfig} ./config/mpd/mpd.conf

            media-init
          '';
        };
      }
    );
}
