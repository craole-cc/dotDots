{
  toolkit,
  entryAfter,
  binaries,
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
    # A changing manifest invalidates VS Code's extension cache while
    # leaving the actual declarative extension directories as links.
    "${mk ".extensions-immutable.json"}" = {
      text = pkgs.vscode-utils.toExtensionJson profile.extensions;
      onChange = ''
        ${binaries.rm} -f \
          "${mk "extensions.json"}" \
          "${mk ".init-default-profile-extensions"}"
      '';
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
    pruneUndeclaredVSCodeExtensions = entryAfter ["linkGeneration"] ''
      extension_dir=${escapeShellArg app.directories.extension}
      for installed in "$extension_dir"/*; do
        [ -d "$installed" ] || [ -L "$installed" ] || continue
        declared=0
        for expected in ${declaredExtensions}; do
          if [ "$installed" = "$expected" ]; then
            declared=1
            break
          fi
        done
        [ "$declared" = 1 ] || ${binaries.rmf} "$installed"
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

        ${binaries.mkdir} -p "$(${binaries.dirname} "$target")"
        ${binaries.rm} -f "$target"
        ${binaries.install} -m 0644 "$source" "$target"
      }

      materialise_json ${for "settings"} "${mk "settings.json"}"
      materialise_json ${for "keybindings"} "${mk "keybindings.json"}"
    '';
  };
in {
  file = app.files.extension // extensions;
  activation = activation // dms;
}
