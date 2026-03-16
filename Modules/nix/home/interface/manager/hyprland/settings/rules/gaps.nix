{specialWorkspaceNames ? [], ...}: let
  specialRule = name: "special:${name}, gapsout:0, gapsin:0, bordersize:0, shadow:false";
in {
  workspace =
    [
      "w[tv1], gapsout:0, gapsin:0, bordersize:0"
      "f[1], gapsout:0, gapsin:0, bordersize:0"
    ]
    ++ map specialRule specialWorkspaceNames;

  windowrule = [
    "border_size 0, match:float 0, match:workspace w[tv1]s[false]"
    "rounding 0, match:float 0, match:workspace w[tv1]s[false]"
  ];
}
