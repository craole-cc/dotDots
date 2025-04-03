{paths,...}:[
{
    name = "DOTS";
    eval = "$PRJ_ROOT";
  }
{
    name = "FLAKE";
    eval = "$PRJ_ROOT";
  }
  {
    name = "PRJ_BIN";
    prefix =
      let
        inherit (paths.parts) bin;
        shellscript = "$PRJ_ROOT" + bin.shellscript;
        rust = "$PRJ_ROOT" + bin.rust;
        dots = "$PRJ_ROOT" + bin.scripts.dots;
        mods = "$PRJ_ROOT" + bin.scripts.mods;
      in
      ''
        ${shellscript}:${rust}:${dots}:${mods}
      '';
  }
  {
    name = "PATH";
    prefix = "$PRJ_BIN";
  }
  {
    name = "PRJ_CACHE";
    eval = "$PRJ_ROOT/.cache";
  }
  {
    name = "PRJ_CONFIG";
    eval = "$PRJ_ROOT/.config";
  }
  # {
  #   name = "TREEFMT_CONFIG";
  #   eval = treefmt.configFile;
  # }
]
