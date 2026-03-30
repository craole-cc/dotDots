{
  lib,
  flatten ? false,
  ...
}: let
  __exports = {
    namespaced = {
      inherit
        testing
        tracing
        ;
    };
    flattened =
      {}
      // testing
      // tracing
      // {};
  };

  inherit (lib) debug;

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
      ;
  };

  testing = {
    inherit
      (debug)
      runTests
      testAllTrue
      ;
  };
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
