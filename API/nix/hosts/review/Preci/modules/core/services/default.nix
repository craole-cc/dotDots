{
  host,
  lix,
  ...
}: let
  inherit (lix.lists) elem;

  inherit (host.principals) primary;
  inherit (host.interface) desktops;

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
      plasma6.enable = elem "plasma" desktops;
    };

    wyoming = {
      #? `faster-whisper` and `piper` declare `servers` as an attribute set of
      #? named instances -- `attrsOf (submodule ...)`, defaulting to `{}` -- so
      #? a server is enabled by giving it a name, not by setting `enable` on
      #? `servers` itself. `openwakeword` is a single service with an `enable`
      #? directly, so the two shapes are not interchangeable.
      faster-whisper.servers.voice = {
        enable = true;
        language = "en";
      };

      piper.servers.voice.enable = true;
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
