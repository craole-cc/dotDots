# flake.nix
{
  description = "Comprehensive media environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  in {
    devShells = builtins.listToAttrs (map (system: {
        name = system;
        value = let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              #| Video
              (mpv.override {
                scripts = with mpvScripts; [
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
              })
              freetube
              mpvc
              yt-dlp

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
            ];
          };
        };
      })
      supportedSystems);
  };
}
