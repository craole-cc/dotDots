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

    # tiling = {
    #   id = "3040216e-31b3-41b6-9b91-767980dc298f";
    #   tiles = {
    #     layoutDirection = "horizontal";
    #     tiles = [
    #       {
    #         width = 0.5;
    #       }
    #       {
    #         layoutDirection = "vertical";
    #         tiles = [
    #           {
    #             height = 0.5;
    #           }
    #           {
    #             height = 0.5;
    #           }
    #         ];
    #         width = 0.5;
    #       }
    #     ];
    #   };
    # };
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
    {
      appId = "foot-quake";
      rules = {
        skipTaskbar = true;
        skipPager = true;
        maximizeVertically = true;
        maximizeHorizontally = true;
      };
    }
  ];
}
