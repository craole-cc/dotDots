{lix, ...} @ args:
lix.attrsets.aggregation.mkShellFragments {
  dirs = [
    ./environment
    ./packages/tools
    ./middleware
    ./packages/scripts
    ./hooks
  ];
  inherit args;
}
