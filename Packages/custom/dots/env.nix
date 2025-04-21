{paths, ...}: [
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
    prefix = let
      inherit (paths.local.binaries) sh rs;
      dots = "$PRJ_ROOT" + "/Scripts";
    in ''
      ${sh}:${rs}:${dots}
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
