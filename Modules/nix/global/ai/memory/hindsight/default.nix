{lix, ...} @ args:
lix.attrsets.aggregation.mkShellFragments {
  dirs = [
    ./environment
    ./packages
    ./hooks
  ];
  inherit args;
}
