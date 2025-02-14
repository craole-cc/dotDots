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
      in {
        nixpkgs.config.allowUnfree = true;
        devShells.default = mkShell {
          buildInputs = with pkgs;
            [
              #| Video tools
              mpv
              mpvc
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
              btop
              curl
              fzf
              jq
              libnotify
              mediainfo
              rlwrap
              socat
              xclip
            ]
            ++ (with mpvScripts; [
              uosc
              memo
              quack
              mpris
              reload
              cutter
              evafast
              autosub
              smartskip
              skipsilence
              chapterskip
              sponsorblock
              quality-menu
              inhibit-gnome
              mpv-notify-send
              webtorrent-mpv-hook
              mpv-playlistmanager
            ]);

          shellHook = ''
            printf "🎬 Comprehensive Media Environment Loaded!"

            #@ Set up directory structure
            mkdir -p {bin,config/{mpv/scripts,mpd/playlists},music,videos}

            #@ Copy and process config files
            cp -f ${mpvScript} ./bin/mpv
            cp -f ${ytdScript} ./bin/ytd
            cp -f ${mpvConfig} ./config/mpv/mpv.conf
            cp -f ${mpdConfig} ./config/mpd/mpd.conf

            #@ Set up executable scripts
            chmod +x bin/*
            PATH="$PATH:$PWD/bin"
            export PATH

            #@ Set up aliases
            alias radio='curseradio'

            #@ Print usage message
            printf "\n\nVideo Tools:"
            printf "\n  mpv      - Enhanced MPV with custom config"
            printf "\n  ytd      - Download videos (usage: ytd <url> [quality])"

            printf "\n\nImage Viewers:"
            printf "\n  feh      - Light image viewer"
            printf "\n  imv      - Alternative image viewer"

            printf "\n\nMusic & Radio:"
            printf "\n  ncmpcpp  - Music player (music dir: music)"
            printf "\n  radio    - Terminal radio"
            echo
          '';
        };
      }
    );
}
