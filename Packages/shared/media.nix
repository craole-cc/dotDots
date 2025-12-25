{pkgs}: let
  packages = with pkgs; [
    mpv
    ffmpeg-full
    yt-dlp
    mediainfo
    mkvtoolnix
  ];

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
