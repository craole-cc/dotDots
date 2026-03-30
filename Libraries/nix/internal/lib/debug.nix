{lib, ...}: let
  __exports =
    {
      inherit
        testing
        tracing
        ;
    }
    // testing
    // tracing
    // {};

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
  __exports
