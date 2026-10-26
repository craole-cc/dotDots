{
  toolkit,
  dms-shell,
  ...
}: let
  inherit (toolkit) binaries;
  inherit (binaries) chmodRuw patchd;
  inherit (dms-shell.package) overrideAttrs;

  package = overrideAttrs (previous: {
    #> Patch the Go backend and QML before make sync-shell embeds the frontend into the executable.
    postPatch =
      (previous.postPatch or "")
      + ''
        ${chmodRuw} ../quickshell
        ${patchd} .. -p1 < ${./patches/theme-control.patch}
        ${patchd} .. -p1 < ${./patches/catppuccin-matugen.patch}
      '';
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
