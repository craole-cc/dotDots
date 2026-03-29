{
  bootstrap = import ./bootstrap.nix; # returns: { lib, path } -> lib'
  collisions = import ./collisions.nix; # returns: { lib', collisionStrategy } -> customAttrs -> merged
  env = import ./env.nix; # returns: { lib', path, name, self, safeLib } -> attrset
  scanner = import ./scan.nix; # returns: { lib', env, ... } -> scanDir
  assemble = import ./assemble.nix; # returns: { lib', customLib, path } -> finalLib
}
