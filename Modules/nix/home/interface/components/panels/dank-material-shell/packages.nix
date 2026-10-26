{toolkit, ...}: let
  inherit (toolkit.binaries) chmodRuw patchd;
  inherit (toolkit.records.dms-shell.package) overrideAttrs;

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
    dms = "${package}/bin/dms";
    dmsCall = "${dms} ipc call";
    dmsSet = "${dmsCall} settings set";
  };
in {
  inherit package;
  bins = toolkit.binaries // bins;
}
