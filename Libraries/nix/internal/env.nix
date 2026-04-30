{
  lib,
  paths,
  names,
  self,
  flake,
  safe,
}: {
  #~@ Primary references
  inherit lib names flake;
  src = paths.root;
  _ = self; # ? custom library (extensible self)
  ${names.top} = self; # ? custom library (extensible self)
  library = names.lib;

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
