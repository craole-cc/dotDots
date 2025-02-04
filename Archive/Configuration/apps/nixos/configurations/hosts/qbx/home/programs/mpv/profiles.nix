{
  programs.mpv.profiles = {
    fast = {
      vo = "vdpau";
    };
    "protocol.dvd" = {
      profile-desc = "profile for dvd:// streams";
      alang = "en";
    };
  };
}
