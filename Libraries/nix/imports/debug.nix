{
  lib,
  flatten ? false,
  ...
}: let
  __exports = {
    namespaced = {inherit construction assertions testing tracing;};
    flattened = {} // construction // assertions // testing // tracing // {};
  };

  inherit (lib) debug asserts meta trivial;

  construction = {inherit (meta) hiPrio;};
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
    inherit (trivial) id deepSeq;
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
