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

  tracing = {
    inherit
      (lib.debug)
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
      (lib.debug)
      runTests
      testAllTrue
      ;
  };
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
