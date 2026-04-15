{dots}: let
  inherit (dots) pkgs;
  description = "🎬 Media Development Shell";
  packages = with pkgs; [
    mpv #? Media player
    ffmpeg-full #? Complete FFmpeg with all features
    yt-dlp #? YouTube downloader
    mediainfo #? Media file analyzer
    mkvtoolnix #? Matroska tools
  ];
  shellHook = ''
    cat <<-EOF
      ${description}
      ==========================

      Available tools:
        • mpv: $(mpv --version | head -n1)
        • ffmpeg: $(ffmpeg -version | head -n1)
        • yt-dlp: $(yt-dlp --version)

      EOF
  '';
in {inherit description packages shellHook;}
