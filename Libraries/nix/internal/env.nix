{
  lib,
  paths,
  names,
  self,
  flake',
  safe,
}: let
  base =
    flake'
    // {
      #~@ Primary references
      library = names.lib;
      inherit lib names paths;
      ${names.top} = self; # custom library (extensible self)
      # lix = self; # custom library (extensible self)

      _defaults =
        flake'
        // {inherit lib names paths;};

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
