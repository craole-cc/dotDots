{
  toolkit,
  lix,
  ...
}: let
  inherit (lix.strings.transformation) replaceStrings;
  inherit (toolkit) records write;
  inherit (records.dms-shell) package paths;

  source = paths.outPath;
  patch = write.source {
    name = "dms-patched-source";
    src = source;
    patches = [./patches/theme-control.patch ./patches/catppuccin-matugen.patch];
  };

  #? Upstream builds the backend from core/ and installs QML from the full tree.
  pkg = package.overrideAttrs (previous: {
    src = "${patch}/core";
    postInstall = replaceStrings [source] ["${patch}"] previous.postInstall;
    passthru = (previous.passthru or {}) // {shellSource = "${patch}/quickshell";};
  });
  bins = rec {
    dms = "${package}/bin/dms";
    dmsCall = "${dms} ipc call";
    dmsSet = "${dmsCall} settings set";
  };
in {
  inherit bins;
  binaries = bins;
  package = pkg;
}
