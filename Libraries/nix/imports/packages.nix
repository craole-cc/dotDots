{
  lib,
  flatten ? false,
  ...
}: let
  __exports = {
    namespaced = {inherit construction;};
    flattened = {} // construction // {};
  };

  inherit (lib) meta;

  construction = {inherit (meta) hiPrio;};
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
