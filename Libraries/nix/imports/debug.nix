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

  inherit (lib) debug asserts trivial;

  tracing = {
    inherit
      (debug)
      trace
      traceIf
      traceVal
      traceValFn
      traceSeq
      traceSeqN
      traceValSeq
      traceValSeqN
      addErrorContext
      ;
    inherit (trivial) id;
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
