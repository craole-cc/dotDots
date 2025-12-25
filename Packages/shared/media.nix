{
  pkgs,
  platform,
}: let
  inherit (pkgs.lib.lists) optionals;
  packages = with pkgs;
    [
      mpv
      ffmpeg-full
      yt-dlp
      mediainfo
      mkvtoolnix
    ]
    ++ optionals platform.isLinux [vlc];

  shellHook = ''
    cat <<-EOF
      🎬 Media Development Shell
      ==========================

      Available tools:
        • mpv: $(mpv --version | head -n1)
        • ffmpeg: $(ffmpeg -version | head -n1)
        • yt-dlp: $(yt-dlp --version)

      EOF
  '';
in
  pkgs.mkShell {
    name = "media-dev";
    inherit packages shellHook;
  }
