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
    flake-utils.lib.eachDefaultSystem (system: let
      paths = rec {
        home = "/home/craole/.dots/Flakes/media";
        mod = ./modules;
        bin = home + "/bin";
        cfg = home + "/config";
        vid = home + "/videos";
        mus = home + "/music";
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
        src = paths.mod + "/mpv/cmd.sh";
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
        src = paths.mod + "/ytd/cmd.sh";
        isExecutable = true;
        ytdlp = pkgs.yt-dlp;
        videos = paths.videos;
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

          #@ Set up directory structure
          mkdir -p {${paths.bin},${paths.cfg}/{mpd,mpv}}
          unalias ytd mpv

          #@ Copy and process config files
          cp -f ${mpvConfig} ${paths.cfg}/mpv/mpv.conf
          cp -f ${ytdConfig} ${paths.cfg}/ytd/yt-dlp.conf


          #@ Set up executable scripts
          cp -f ${ytdCommand} ${paths.bin}/ytd
          find "${paths.bin}" -type f -exec chmod +x {} +
          PATH="$PATH:${paths.bin}"
          export PATH

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
    });
}
#@ Initialize the apps
# init-ytd
# init-mpv
# cp -f ${ytdInit} ${flakeBin}/init-ytd
# cp -f ${mpvInit} ${flakeBin}/init-mpv
# cp -f ${mpvCommand} ${flakeBin}/mpv

