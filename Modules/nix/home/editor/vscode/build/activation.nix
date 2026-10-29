{
  entryAfter,
  dms,
  lix,
  app,
  profile,
  pkgs,
  ...
}: let
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (lix.strings.construction) concatStringsSep;
  inherit (lix.filesystem.primitives) concat;

  declaredExtensions = concatStringsSep " " (map escapeShellArg (attrNames app.files.extension));

  extensions = let
    mk = stem:
      concat {
        inherit stem;
        root = app.directories.extension;
      };
  in {
    # Declarative manifest of the profile. Recent VS Code builds do not read
    # this file, so cache invalidation belongs to the prune hook below.
    "${mk ".extensions-immutable.json"}" = {
      text = pkgs.vscode-utils.toExtensionJson profile.extensions;
    };
  };

  activation = let
    mk = stem:
      concat {
        inherit stem;
        root = app.directories.configuration;
      };
    for = type: escapeShellArg app.files.${type};
  in {
    # Everything in the extension directory is owned by this profile. Editor
    # state (extension cache, update bookkeeping) is removed as well: an
    # auto-updated `<id>-<version>` directory left behind in extensions.json
    # is what surfaces as "Unable to read file '<id>-<version>/package.json'".
    pruneUndeclaredVSCodeExtensions = entryAfter ["linkGeneration"] ''
      extension_dir=${escapeShellArg app.directories.extension}
      for installed in "$extension_dir"/* "$extension_dir"/.??*; do
        [ -e "$installed" ] || [ -L "$installed" ] || continue
        case ''${installed##*/} in
          # Volatile paths owned by the editor or by the DMS theme seed.
          .extensions-immutable.json|danklinux.dms-theme-*) continue ;;
        esac
        declared=0
        for expected in ${declaredExtensions}; do
          if [ "$installed" = "$expected" ]; then
            declared=1
            break
          fi
        done
        [ "$declared" = 1 ] || ${lix.toolkit.binaries.rmrf} "$installed"
      done
    '';

    # VS Code writes settings/keybindings itself. Materialise the
    # declarative profile as regular files on activation instead of
    # linking them into the Nix store, so runtime saves do not fail
    # EROFS. A future activation restores the declared baseline.
    materialiseVSCodeProfile = entryAfter ["linkGeneration"] ''
      materialise_json() {
        source="$1"
        target="$2"

        ${lix.toolkit.binaries.mkdirp} "$(${lix.toolkit.binaries.dirname} "$target")"
        ${lix.toolkit.binaries.rmf} "$target"
        ${lix.toolkit.binaries.install0644} "$source" "$target"
      }

      materialise_json ${for "settings"} "${mk "settings.json"}"
      materialise_json ${for "keybindings"} "${mk "keybindings.json"}"
    '';
  };
in {
  file = app.files.extension // extensions;
  activation = activation // dms;
}
