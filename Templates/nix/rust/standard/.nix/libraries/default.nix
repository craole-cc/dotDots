/**
* Nix Library Assembly Module
*
* This module serves as the main entry point for building a comprehensive Nix
* library by composing multiple specialized namespaces in dependency order.
*
* Process:
* 1. Initializes with the standard nixpkgs lib (or custom lib if provided)
* 2. Bootstraps lib.assembly from assembly.nix for core assembly functionality
* 3. Sequentially merges each namespace into the accumulated library
*
* Dependencies are resolved in order, ensuring each namespace has access to
* previously loaded modules and the assembly utilities.
*
* Namespaces (in dependency order):
* - trivial: Basic utility functions and primitives
* - filesystem: File and path manipulation utilities
* - attrsets: Attribute set operations and transformations
* - strings: String processing and manipulation functions
* - packages: Package management and handling utilities
* - shells: Shell environment and configuration helpers
*
* @param {lib} lib - Optional custom Nix library to extend. Defaults to nixpkgs.lib
* @returns {lib} Extended library object containing all assembled namespaces and utilities
*/
/**
libraries/default.nix

Bootstrap lib.assembly from assembly.nix, then sequentially extend lib with
each namespace.  Order = dependency order; later entries see earlier ones on
their incoming `lib`.
*/
{
  lib,
  paths,
}: let
  lib' = lib.extend (final: _:
    import ./assembly.nix {
      lib = final;
      inherit paths;
    });
in
  lib'.assembly.assemble {
    start = lib';
    scope = acc: acc;
    extraArgs = {inherit paths;};
    entries = [
      ./trivial
      ./filesystem
      ./attrsets
      ./strings
      ./packages
      # ./templates
      ./shells
    ];
    ignore = ["tests" "assembly.nix" "format"];
  }
