{
  package,
  builders,
  libraries,
  ...
}: let
  lix = libraries;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.filesystem.access) readFile;
  inherit (lix.strings.construction) fromJSON;
  inherit (lix.strings.transformation) removePrefix;
  release = fromJSON (readFile ../release.json);
in
  package.override (arguments: {
    # Source follows upstream HEAD. xin snapshots the latest release tag during
    # updates; evaluation reads local metadata without mutable network requests.
    version = "${removePrefix "v" release.tag_name}+unstable.${arguments.rev}";
    extraDependencyGroups = ["messaging"];
    callPackage = path: overrides:
      arguments.callPackage path (overrides
        // optionalAttrs (baseNameOf path == "python.nix") {
          pythonSrc = builders.applyPatches {
            name = "hermes-scheduled-routes-source";
            src = overrides.pythonSrc;
            patches = [./scheduled-routes.patch ../handoff/named-team.patch ./plugin-catalog.patch ./plugin-environment.patch];
            patchFlags = ["-p1" "--fuzz=0"];
            postPatch = ''
              # Keep the reviewed fallback catalog in the sealed Python wheel.
              cp -R plugin-catalog hermes_cli/data/plugin-catalog
              # PM inspects core dependency metadata after wheel installation.
              mkdir -p pm/core
              cp uv.lock pyproject.toml setup.py pm/core/
              cp ${./scheduled_routes.py} agent/scheduled_routes.py
              cp ${../handoff/team_handoff.py} tools/team_handoff.py
            '';
          };
        });
  })
