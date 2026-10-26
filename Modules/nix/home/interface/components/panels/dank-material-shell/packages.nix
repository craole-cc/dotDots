{
  toolkit,
  dms-shell,
  pkgs,
  inputs,
  lix,
  ...
}: let
  inherit (toolkit) binaries;
  inherit (lix.strings.transformation) replaceStrings;
  source = inputs.dank-material-shell.outPath;
  patchedSource = pkgs.applyPatches {
    name = "dms-patched-source";
    src = source;
    patches = [./patches/theme-control.patch ./patches/catppuccin-matugen.patch];
  };

  # Upstream builds the backend from core/ and installs QML from the full tree.
  package = dms-shell.package.overrideAttrs (previous: {
    src = "${patchedSource}/core";
    postInstall = replaceStrings [source] ["${patchedSource}"] previous.postInstall;
    passthru =
      (previous.passthru or {})
      // {
        shellSource = "${patchedSource}/quickshell";
      };
  });

  bins = rec {
    inherit
      (toolkit.binaries)
      chmodRuw
      patchd
      chmod
      cmp
      dirname
      install0600
      install0644
      jaq
      mkdirp
      mktemp
      mvf
      rmf
      ;

    dms = "${package}/bin/dms";
    dmsCall = "${dms} ipc call";
    dmsSet = "${dmsCall} settings set";
  };
in {
  inherit package;
  binaries = binaries // bins;
}
