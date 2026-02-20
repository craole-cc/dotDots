{pkgs, ...}: {
  package = with pkgs;
  with mpv-unwrapped;
    wrapper {mpv = override {ffmpeg = ffmpeg-full;};};
  defaultProfiles = ["gpu-hq"];
  config = {
    profile = "gpu-hq";
    force-window = true;
    ytdl-format = "bestvideo+bestaudio";
  };
}
