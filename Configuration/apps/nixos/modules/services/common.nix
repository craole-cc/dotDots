{ specialArgs, lib, ... }:
let
  inherit (specialArgs.host) ollama people capabilities;
  inherit (specialArgs.host.cpu) brand;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.lists)
    elem
    filter
    length
    head
    ;

  autologinUsers = filter (user: user.autoLogin or false) people;
  autologinUser = if length autologinUsers >= 1 then (head autologinUsers).name else null;

  hasBluetooth = elem "bluetooth" capabilities;
  hasBattery = elem "battery" capabilities;
  hasVideo = elem "video" capabilities;
  hasAudio = elem "audio" capabilities;
  hasRemote = elem "remote" capabilities;
  hasInput = elem "mouse" capabilities || elem "touchpad" capabilities;
  hasBareMetal = elem brand [
    "amd"
    "intel"
    "x86"
  ];
in
{
  services =
    #@ Check for autoLogin constraints
    assert
      length autologinUsers <= 1
      || throw "Error: Multiple users designated for autologin (${
        concatStringsSep ", " (map (user: user.name) autologinUsers)
      }). Check the 'host.people' configuration.";
    {
      displayManager.autoLogin = {
        enable = autologinUser != null;
        user = autologinUser;
      };

      blueman =
        if hasBluetooth then
          {
            enable = true;
          }
        else
          { };

      kmscon = {
        enable = true;
        inherit autologinUser;
      };

      libinput =
        if hasInput then
          {
            enable = true;
          }
        else
          { };

      ollama = {
        inherit (ollama) enable;
        loadModels = ollama.models;
      };

      pipewire =
        if hasAudio then
          {
            enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
            jack.enable = true;
            extraConfig.pipewire."92-low-latency" = {
              context.properties.default.clock = {
                rte = 48000;
                quantum = 32;
                min-quantum = 32;
                max-quantum = 32;
              };
            };
          }
        else
          { };

      redshift =
        if hasVideo then
          {
            enable = true;
            brightness = {
              day = "1";
              night = "0.75";
            };
            temperature = {
              day = 5500;
              night = 3800;
            };
          }
        else
          { };

      rsyncd = {
        enable = true;

      };

      tailscale =
        if hasRemote then
          {
            enable = true;
          }
        else
          { };

      udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="hidraw", GROUP="users", MODE="0660", TAG+="uaccess"
      '';

      upower =
        if hasBattery then
          {
            enable = true;
          }
        else
          { };
    };
  security.rtkit.enable = true;
  # sound.enable = false;
  hardware = {
    enableRedistributableFirmware = hasBareMetal;

    cpu =
      if hasBareMetal then
        {
          ${brand}.updateMicrocode = true;
        }
      else
        { };

    bluetooth = {
      enable = hasBluetooth;
      settings.General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };

    # sensor =
    #   if hasBareMetal then
    #     {
    #       iio.enable = true;
    #       hddtemp.enable = true;
    #     }
    #   else
    #     { };
  };
}
