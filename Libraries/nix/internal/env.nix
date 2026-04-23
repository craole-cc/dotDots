{
  lib',
  path,
  name,
  self,
  safeLib,
}: {
  #~@ Primary references
  inherit path name;
  lib = lib'; # ? nixpkgs lib
  _ = self; # ? custom library (extensible self)
  src = path;
  library = name;

  #~@ Short aliases
  l = lib';
  x = self;
  s = safeLib;

  #~@ Structured access
  libs = {
    nixpkgs = lib';
    custom = self;
    safe = safeLib;
  };
}
