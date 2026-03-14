{pkgs, ...}: {
  # package = with pkgs; [ffmpeg-full];
  # with mpv-unwrapped;
  #   wrapper {mpv = override {ffmpeg = ffmpeg-full;};};

  defaultProfiles = ["gpu-hq"];

  # config = {
  #   profile = "gpu-hq";
  #   force-window = true;
  #   ytdl-format = "bestvideo+bestaudio";
  #   cache-default = 4000000;
  # };

  includes = [
    "$DOTS/Configuration/mpv/config"
  ];
}
