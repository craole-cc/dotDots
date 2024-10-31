{ inputs, ... }:
let
  libs = import ./libraries { inherit inputs; };
in
{
  inherit libs;
  imports = [
    ./options
  ];
}
