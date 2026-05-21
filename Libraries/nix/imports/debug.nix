{
  lib,
  flatten ? false,
  ...
}: let
  __exports = {
    namespaced = {inherit assertions testing tracing;};
    flattened =
      {}
      // assertions
      // testing
      // tracing
      // {};
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
    inherit (builtins) tryEval;
  };

  assertions = {
    inherit (asserts) assertMsg;
  };

  testing = {
    inherit (debug) runTests testAllTrue;
  };
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
