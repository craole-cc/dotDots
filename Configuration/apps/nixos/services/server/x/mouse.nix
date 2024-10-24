{...}:{
  #| Touchpad
  services.xserver.libinput = {
    enable = true;
    mouse = {
      disableWhileTyping = true;
      # naturalScrolling = true;
    };
  };
}