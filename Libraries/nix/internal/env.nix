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
    src = paths.flake;
    ${names.top} = self; # ? custom library (extensible self)
    lix = self; # ? custom library (extensible self)

    _defaults = {
      src = paths.flake;
      inherit lib names flake paths;
    };

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
