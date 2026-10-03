# Entry point for `nixos-rebuild`, which passes its `-I nixos-config=...` argument
# to `nix-build` as a *path*. A path is imported as a module set, so a host whose
# `default.nix` is a function of {lib, lix, ...} would never be called -- Nix
# would look for module attributes on the function itself, and fail with
# "attribute 'lix' missing" or, when the function takes only defaulted
# arguments, recurse while probing for those arguments.
#
# This file *calls* the host and returns the resulting module set, so the
# evaluator sees modules rather than a function.
#
#   sudo nixos-rebuild switch \
#     -I nixos-config=<repo>/API/nix/hosts/Preci/system.nix
{
  lib ? import <nixpkgs/lib>,
  ...
}:
import ./. {inherit lib;}