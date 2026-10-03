{
  host,
  lix,
  ...
}: let
  inherit (lix.lists) elem;

  primary = host.principals.primary;

  #? `host.functionalities` is the resolved *record* (`{names, set, values,
  #? ...}`), not a bare list. Membership is read off its `names` list;
  #? scanning the record itself would make every test false.
  has = name: elem name host.functionalities.names;
in {
  services = {
    openssh.enable = true;
    tailscale.enable = has "vpn";
    libinput.enable = has "touchpad";
    printing.enable = true;

    pipewire = {
      enable = has "audio";
      alsa.enable = has "audio";
      alsa.support32Bit = has "audio";
      pulse.enable = has "audio";
    };

    displayManager = {
      enable = true;
      autoLogin = {
        enable = primary.autoLogin;
        user = primary.name;
      };
    };

    desktopManager = {
      plasma6.enable = elem "plasma" host.interface.desktops;
    };

    wyoming = {
      #? `faster-whisper` and `piper` expose `servers`; `openwakeword` is a
      #? single service with an `enable`. They are not interchangeable.
      faster-whisper.servers = {
        enable = true;
        language = "en";
      };

      piper.servers.enable = true;
      openwakeword.enable = true;
    };
    xserver = {
      enable = false;
      xkb = {
        layout = primary.interface.keyboard.layout;
        variant = primary.interface.keyboard.variant;
      };
    };
  };
}
