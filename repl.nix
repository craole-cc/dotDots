let
  flake = builtins.getFlake (toString ./.);
  # nixpkgs = import <nixpkgs> { };
in
flake
# // {
#   inherit nixpkgs;
# Add specific variables here if needed
# For example:
# myConfig = flake.outputs.nixosConfigurations.myNodeName.config;
# }
