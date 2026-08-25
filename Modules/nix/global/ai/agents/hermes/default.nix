{lix, ...} @ args:
lix.attrsets.aggregation.mkShellFragments {
  dirs = [
    ./environment
    ./tools
    ./middleware
    ./scripts
    ./hooks
  ];
  inherit args;
}
