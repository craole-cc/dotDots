{
  lib,
  paths,
  names,
  self,
  flake,
  safe,
}:
{
  #~@ Primary references
  library = names.lib;
  inherit lib names flake;
  inherit (paths) src;
  ${names.top} = self; # ? custom library (extensible self)
  lix = self; # ? custom library (extensible self)

  #~@ Short aliases
  l = lib;
  x = self;
  s = safe;

  #~@ Structured access
  libs = {
    nixpkgs = lib;
    custom = self;
    inherit safe;
  };
}
