{pkgs}: let
  # Media-related packages for video/audio processing
  packages = with pkgs; [
    mpv #? Media player
    ffmpeg-full #? Complete FFmpeg with all features
    yt-dlp #? YouTube downloader
    mediainfo #? Media file analyzer
    mkvtoolnix #? Matroska tools
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

  # Standalone shell environment for media-only work
  shell = pkgs.mkShell {
    name = "media-dev";
    inherit packages shellHook;
  };
in {
  #> Export packages list for inclusion in other shells (e.g., dots)
  inherit packages;

  #> Export shell for standalone use via `nix develop .#media`
  inherit shell;
}
