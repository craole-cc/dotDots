# importer.nix
{ ... }:
let
  importAll =
    dir:
    with builtins;
    listToAttrs (
      map (
        name:
        let
          path = "${dir}/${name}";
        in
        {
          name = name;
          value = import (path + "/default.nix");
        }
      ) (attrNames (readDir dir))
    );
in
{
  inherit importAll; # Export the importAll function
}
