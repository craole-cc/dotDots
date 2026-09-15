{lix, ...} @ args:
lix.attrsets.aggregation.mkShellFragments {
  dirs = [
    ./environment
    ./packages
    ./hooks
  ];
  args = args // {env = args.env or {};};
}
