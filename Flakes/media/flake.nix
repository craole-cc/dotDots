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
      flakeHome = "/home/craole/.dots/Flakes/media";
      flakeMod = "${flakeHome}/modules";
      flakeBin = "${flakeHome}/bin";
      flakeCfg = "${flakeHome}/config";
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
      ytdInit = pkgs.substituteAll {
        src = "${flakeMod}/ytd/init.sh";
        isExecutable = true;
        ytdlp = pkgs.yt-dlp;
      };

      mpvInit = pkgs.substituteAll {
        src = "${flakeMod}/mpv/init.sh";
        isExecutable = true;
        mpv = pkgs.mpv.override {
          scripts = mpvEnhanced;
        };
      };

      mpvConfig = pkgs.substituteAll {
        src = "${flakeMod}/mpv/settings.conf";
        ytdlp = pkgs.yt-dlp;
      };
      # mpvInput = "${flakeMod}/mpv/input.conf";
      # mpdConfig = "${flakeMod}/mpd/settings.conf";
      # mpvConfig =
      #   pkgs.runCommand "mpv-config" {
      #     src = ./modules/mpv;
      #   } ''
      #     #@ Create the config directory
      #     mkdir -p $out/config
      #     cp -r $src/* $out/config/
      #     #@ Ensure yt-dlp path is set in settings.conf
      #     echo "ytdl_path=${pkgs.yt-dlp}/bin/yt-dlp" >> $out/config/settings.conf
      #     echo "script-opts=ytdl_hook-ytdl_path=${pkgs.yt-dlp}/bin/yt-dlp" >> $out/config/settings.conf
      #   '';
      # mpvEnhanced = pkgs.symlinkJoin {
      #   name = "mpv";
      #   paths = [
      #     (pkgs.mpv.override {
      #       scripts = with pkgs.mpvScripts; [
      #         uosc
      #         memo
      #         quack
      #         mpris
      #         reload
      #         cutter
      #         evafast
      #         autosub
      #         smartskip
      #         skipsilence
      #         chapterskip
      #         sponsorblock
      #         quality-menu
      #         inhibit-gnome
      #         mpv-notify-send
      #         webtorrent-mpv-hook
      #         mpv-playlistmanager
      #       ];
      #     })
      #   ];
      #   buildInputs = [pkgs.makeWrapper];
      #   postBuild = ''
      #     wrapProgram $out/bin/mpv \
      #       --set MPV_HOME "${mpvConfig}/config" \
      #       --set MPV_CONFIG_DIR "${mpvConfig}/config" \
      #       --prefix PATH : "${pkgs.yt-dlp}/bin"
      #   '';
      # };
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
          mpvEnhanced
          mpvc
          # yt-dlp
        ];

        shellHook = ''
          printf "🎬 Comprehensive Media Environment Loaded!\n\n"

          #@ Set up directory structure
          mkdir -p {${flakeBin},${flakeCfg}/{mpd,mpv}}

          #@ Copy and process config files
          cp -f ${mpvConfig} ${flakeCfg}/mpv/mpv.conf

          #@ Show the usage guide
          printf "Video Tools:\n"
          printf "  mpv         - Enhanced MPV with custom config\n"
          printf "  ytd         - Download videos (usage: yt-download <url> [quality])\n\n"

          printf "Image Viewers:\n"
          printf "  feh         - Light image viewer\n"
          printf "  imv         - Alternative image viewer\n\n"

          printf "Music & Radio:\n"
          printf "  ncmpcpp     - Music player (music dir: ${flakeHome}/music)\n"
          printf "  curseradio  - Terminal radio\n\n"
        '';
      };
    });
}
# #@ Set up executable scripts
# cp ${ytdInit} ${flakeBin}/init-ytd
# cp ${mpvInit} ${flakeBin}/init-mpv
# find "${flakeBin}" -type f -exec chmod +x {} +
# PATH="$PATH:${flakeBin}"
# export PATH
# #@ Initialize the apps
# init-ytd
# init-mpv

