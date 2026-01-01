{
  kwin = {
    # edgeBarrier = 0; # Disables the edge-barriers introduced in plasma 6.1
    # cornerBarrier = false;

    # scripts.polonium.enable = true;
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
