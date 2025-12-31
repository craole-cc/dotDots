{_, ...}: let
  inherit (_.inputs.generators) mkInputs mkPackages mkOverlays mkModules;

  resolve = {
    flake,
    host,
    ...
  }: let
    path = flake.outPath;
    inputsUnprocessed = flake.inputs;
    inputs = mkInputs {inherit inputsUnprocessed;};
    packages = mkPackages {inherit inputs;};
    overlays = mkOverlays {
      inherit (inputs) nixpkgs-stable nixpkgs-unstable;
      inherit packages;
      config = {
        allowUnfree = host.packages.allowUnfree or false;
        allowBroken = host.packages.allowBroken or false;
      };
    };
    modules = mkModules {inherit host path inputs;};
  in {inherit inputs modules overlays packages;};

  exports = {
    getInputs = resolve;
    inherit mkInputs mkModules mkOverlays mkPackages;
  };
in
  exports // {_rootAliases = {inherit (exports) getInputs;};}
