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
    ++ (optionals platform.isLinux [
      vlc # VLC has better Linux support
    ])
    ++ (optionals platform.isDarwin [
      # macOS-specific media tools can go here
    ]);

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
