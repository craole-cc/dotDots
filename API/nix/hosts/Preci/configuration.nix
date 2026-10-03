# Build entry point.
#
# `nixos-rebuild -I nixos-config=<path>` hands the path to nix-build, which
# imports it as a module *set*. `default.nix` is a function of
# {lib, lix, specs, ...}, so importing it as a set never calls it: Nix looks for
# module attributes on the function and reports "attribute 'lix' missing", or
# probes the defaulted arguments and reports infinite recursion.
#
# This file calls that function and returns the resulting module set, so the
# evaluator receives modules. This was previously the pre-migration monolith,
# which the modular tree replaced; the name is kept because it is the
# conventional entry point.
#
#   sudo nixos-rebuild switch \
#     -I nixos-config=<repo>/API/nix/hosts/Preci/configuration.nix
{
  lib ? import <nixpkgs/lib>,
  ...
}:
import ./. {inherit lib;}