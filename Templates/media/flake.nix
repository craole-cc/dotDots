{
  description = "Comprehensive Media Environment";

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
        paths = rec {
          home = "/home/craole/.dots/Flakes/media";
          # mod = ./modules;
          mod = home + "/modules";
          bin = home + "/bin";
          cfg = home + "/config";
          dls = home + "/downloads";
        };
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        mpvEnhanced = pkgs.mpv.override {
          scripts = with pkgs.mpvScripts; [
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
          ];
        };

        mpvConfig = pkgs.substituteAll {
          src = paths.mod + "/mpv/settings.conf";
          ytdlp = pkgs.yt-dlp;
        };

        mpvCommand = pkgs.substituteAll {
          src = ./modules/mpv/cmd.sh;
          isExecutable = true;
          mpv = pkgs.mpv.override {
            scripts = mpvEnhanced;
          };
        };

        ytdConfig = pkgs.substituteAll {
          src = paths.mod + "/ytd/settings.conf";
          ytdlp = pkgs.yt-dlp;
        };

        ytdCommand = pkgs.substituteAll {
          isExecutable = true;
          src = ./modules/ytd/cmd.sh;
          cmd = "${pkgs.yt-dlp}/bin/yt-dlp";
          cfg = paths.cfg + "/ytd/yt-dlp.conf";
          mod = paths.mod + "/ytd/settings.conf";
          dls = paths.dls;
          fmt = "1080p";
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
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
          ];

          shellHook = ''
            printf "🎬 Comprehensive Media Environment Loaded!\n\n"

            #@ Deploy scripts
            mkdir -p ${paths.bin}
            cp -f ${ytdCommand} ${paths.bin}/ytd

            #@ Set up executable scripts
            find "${paths.bin}" -type f -exec chmod +x {} +
            PATH="$PATH:${paths.bin}"
            export PATH
            unalias mpv ytd

            #@ Show the usage guide
            printf "Video Tools:\n"
            printf "  mpv         - Enhanced MPV with custom config\n"
            printf "  ytd         - Download videos (usage: yt-download <url> [quality])\n\n"

            printf "Image Viewers:\n"
            printf "  feh         - Light image viewer\n"
            printf "  imv         - Alternative image viewer\n\n"

            printf "Music & Radio:\n"
            printf "  ncmpcpp     - Music player (music dir: ${paths.home}/music)\n"
            printf "  curseradio  - Terminal radio\n\n"
          '';
        };
      }
    );
}
#@ Initialize the apps
# init-ytd
# init-mpv
# cp -f ${ytdInit} ${flakeBin}/init-ytd
# cp -f ${mpvInit} ${flakeBin}/init-mpv
# cp -f ${mpvCommand} ${flakeBin}/mpv
# cp -f ${mpvConfig} ${paths.cfg}/mpv/mpv.conf
# cp -f ${ytdConfig} ${paths.cfg}/ytd/yt-dlp.conf

