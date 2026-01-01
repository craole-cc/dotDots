{nixosConfig, ...}: {
  kwin = {
    edgeBarrier = 0; # Disables the edge-barriers introduced in plasma 6.1
    cornerBarrier = false;

    # scripts.polonium.enable = true;
    nightLight = {
      enable = true;
      mode = "location";
      temperature = {
        day = null;
        night = 4200;
      };
      location = {
        inherit (nixosConfig.location) latitude longitude;
      };
      time = {
        morning = "09:00";
        evening = "17:00";
      };
      transitionTime = 30;
    };
    effects = {
      blur = {
        enable = true;
        strength = 1;
        noiseStrength = 2;
      };
    };
  };

  window-rules = [
    {
      description = "Dolphin";
      match = {
        window-class = {
          value = "dolphin";
          type = "substring";
        };
        window-types = ["normal"];
      };
      apply = {
        noborder = {
          value = true;
          apply = "force";
        };
        # `apply` defaults to "apply-initially"
        maximizehoriz = true;
        maximizevert = true;
      };
    }
  ];
}
