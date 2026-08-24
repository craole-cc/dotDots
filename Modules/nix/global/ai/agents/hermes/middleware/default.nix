{lix, ...} @ args:
lix.attrsets.aggregation.mkShellFragments {
  dirs = [
    ./telegram
    ./whatsapp
  ];
  inherit args;
}
