{lib, ...}: {
  inherit
    (lib.debug)
    #~@ Tracing
    traceIf
    traceVal
    traceValFn
    traceSeq
    traceSeqN
    traceValSeq
    traceValSeqN
    traceValIfNot
    #~@ Testing
    runTests
    testAllTrue
    ;
}
