let
  result = import ./libraries {
    lib = import <nixpkgs/lib>;
    pkgs = import <nixpkgs> {};
  };
in
  builtins.attrNames result._module.args.lix
