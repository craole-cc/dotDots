{nixosConfig, ...}: {
  kwin = {
    edgeBarrier = 0;
    cornerBarrier = false;

    nightLight = {
      enable = true;
      mode = "times";
      temperature = {
        day = null;
        night = 4200;
      };
      location = with nixosConfig.location; {
        latitude = toString latitude;
        longitude = toString longitude;
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
