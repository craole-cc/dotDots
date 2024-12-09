{ specialArgs, ... }:
let
  variables = import ./variables.nix { inherit (specialArgs) paths host; };
in
{
  environment = {
    inherit variables;
  };
}
