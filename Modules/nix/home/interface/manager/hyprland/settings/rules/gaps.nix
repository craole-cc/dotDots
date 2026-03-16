{
  #> Remove borders/rounding when only one tiled window
  # workspace = [
  #   "w[tv1], gapsout:0, gapsin:0"
  #   "f[1], gapsout:0, gapsin:0"
  # ];

  windowrule = [
    "border_size 0, match:float 0, match:workspace w[tv1]s[false]"
    "rounding 0, match:float 0, match:workspace w[tv1]s[false]"
  ];
}
