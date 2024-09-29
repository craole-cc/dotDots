{...}:{
  #| Touchpad
  services.xserver.libinput = {
    enable = true;
    touchpad = {
      disableWhileTyping = true;
      naturalScrolling = true;
    };
  };
}