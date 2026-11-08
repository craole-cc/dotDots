{
  package,
  builders,
  libraries,
  ...
}: let
  lix = libraries;
  inherit (lix.attrsets.construction) optionalAttrs;
in
  package.override (arguments: {
    extraDependencyGroups = ["messaging"];
    callPackage = path: overrides:
      arguments.callPackage path (overrides
        // optionalAttrs (baseNameOf path == "python.nix") {
          pythonSrc = builders.applyPatches {
            name = "hermes-scheduled-routes-source";
            src = overrides.pythonSrc;
            patches = [./scheduled-routes.patch ../handoff/named-team.patch];
            patchFlags = ["-p1" "--fuzz=0"];
            postPatch = ''
              cp ${./scheduled_routes.py} agent/scheduled_routes.py
              cp ${../handoff/team_handoff.py} tools/team_handoff.py
            '';
          };
        });
  })
