{dots}: let
  inherit (dots) pkgs;
  description = "🎬 Media Development Shell";
  packages = with pkgs; [
    mpv # ? Media player
    ffmpeg-full # ? Complete FFmpeg with all features
    exiftool # ? ARW/RAW embedded preview extraction for yazi
    yt-dlp # ? YouTube downloader
    mediainfo # ? Media file analyzer
    mkvtoolnix # ? Matroska tools
    ueberzugpp # ? Terminal image rendering backend for yazi (Wayland)
    yazi # ? File manager (ensure CLI tools available in devshell)
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
in {
  inherit description packages shellHook;
}
