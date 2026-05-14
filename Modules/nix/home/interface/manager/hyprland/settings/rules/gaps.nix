{
  specialWorkspaceNames ? [ ],
  ...
}:
let
  gap = "4";
  border = "0";
  specialRule = name: "special:${name}, gapsout:${gap}, gapsin:${gap}, bordersize:0, shadow:false";
in
{
  workspace = [
    "w[tv1], gapsout:${gap}, gapsin:${gap}, bordersize:${border}"
    "f[1], gapsout:${gap}, gapsin:${gap}, bordersize:${border}"
  ]
  ++ map specialRule specialWorkspaceNames;

  windowrule = [
    "border_size 0, match:float 0, match:workspace w[tv1]s[false]"
    "rounding 0, match:float 0, match:workspace w[tv1]s[false]"
  ];
}
