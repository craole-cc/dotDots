{
  lib,
  paths,
  names,
  self,
  flake,
  safe,
}: let
  base = {
    #~@ Primary references
    library = names.lib;
    inherit lib names flake paths;
    inherit (paths) src;
    ${names.top} = self; # ? custom library (extensible self)
    lix = self; # ? custom library (extensible self)

    #~@ Short aliases
    l = lib;
    x = self;
    s = safe;
  };
in
  base
  // (
    if names.top == "_"
    then {}
    else {_ = self;}
  )
