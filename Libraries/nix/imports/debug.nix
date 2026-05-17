{
  lib,
  flatten ? false,
  ...
}: let
  __exports = {
    namespaced = {inherit testing tracing;};
    flattened = {} // testing // tracing // {};
  };

  inherit (lib) debug asserts;

  tracing = {
    inherit
      (debug)
      traceIf
      traceVal
      traceValFn
      traceSeq
      traceSeqN
      traceValSeq
      traceValSeqN
      traceValIfNot
      addErrorContext
      ;
    inherit (asserts) assertMsg;
  };

  testing = {inherit (debug) runTests testAllTrue;};
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
