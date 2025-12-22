{lib, ...}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.lists) foldl';
  inherit (lib.modules) setDefaultModuleLocation;

  /**
  Process a single flake input by adding module location metadata to its modules.

  Iterates through the specified module categories (nixosModules and homeModules)
  within a flake input and applies `setDefaultModuleLocation` to each module. The location
  string follows the format: `<flake-name>.<module-category>.<module-name>`.

  # Arguments
  - {string} name - The attribute name of the flake input (e.g., "nixpkgs")
  - {attrset} input - The flake input attribute set

  - # Return
  - {attrset} - The processed input with location metadata added to modules

  # Example
  ```nix
  input = {
    nixosModules = { foo = ...; };
    homeModules = { bar = ...; };
  };

  processInput "my-flake" input

  # => {
    nixosModules = { foo = <module-with-location-"my-flake.nixosModules.foo">; };
    homeModules = { bar = <module-with-location-"my-flake.homeModules.bar">; };
  }
  ```
  */
  processInput = name: input:
    foldl' (
      acc: module-class:
        if acc ? ${module-class}
        then
          acc
          // {
            ${module-class} =
              mapAttrs (
                module-name: _module:
                  setDefaultModuleLocation "${name}.${module-class}.${module-name}" _module
              )
              acc.${module-class};
          }
        else acc
    )
    input ["nixosModules" "homeModules"];

  /**
  Process all flake inputs by adding module location metadata.

  Applies `processInput` to each flake input in the provided set, ensuring all
  modules have proper location information for better error messages and debugging.
  The location metadata helps identify the source of modules when NixOS or Home
  Manager encounter errors during evaluation.

  # Arguments
  - {attrset} rawInputs - A set of flake inputs

  # Return
  - {attrset} - All inputs processed with module location metadata

  # Example
  ```nix
  {
    inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
      home-manager.url = "github:nix-community/home-manager";
    };

    outputs = { self, nixpkgs, home-manager, ... }:
      let
        processedInputs = processInputs { inherit nixpkgs home-manager; };
      in {
        nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
          modules = [
            processedInputs.nixpkgs.nixosModules.my-module
            processedInputs.home-manager.nixosModules.home-manager
          ];
        };
      };
  }
  ```
  */
  processInputs = rawInputs: mapAttrs processInput rawInputs;
in {
  inherit processInput processInputs;
  _rootAliases = {inherit processInputs;};
}
