{ specialArgs, ... }:
let
  variables = import ./variables.nix { inherit (specialArgs) paths; };
in
{
  inherit variables;
}
