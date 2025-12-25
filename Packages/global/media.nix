{pkgs}: let
  packages = with pkgs; [
    mpv
    ffmpeg-full
    yt-dlp
    mediainfo
    mkvtoolnix
    vlc
  ];

  shellHook = ''
    echo "🎬 Media Development Shell"
    echo "=========================="
    echo ""
    echo "Available tools:"
    echo "  • mpv: $(mpv --version | head -n1)"
    echo "  • ffmpeg: $(ffmpeg -version | head -n1)"
    echo "  • yt-dlp: $(yt-dlp --version)"
    echo ""
  '';
in
  pkgs.mkShell {
    name = "media-dev";
    inherit packages shellHook;
  }
