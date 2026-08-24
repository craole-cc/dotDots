{lix, ...} @ args:
lix.attrsets.aggregation.mkShellFragments {
  dirs = [
    ./telegram
    ./whatsapp
    ./discord
  ];
  inherit args;
}
