{lib, ...}: let
  inherit (lib) mapAttrsToList filterAttrs;
in {
  # Generate documentation symlinks
  generateSymlinks = {
    src ? ".",
    dest ? "Documentation",
    createMissingDirs ? true,
  }: let
    # Get the library instance
    libInstance = (import ./default.nix) {inherit lib;};

    # Collect all modules
    collectModules = attrs: let
      leaves = filterAttrs (_: v: v ? __meta) attrs;
      nested = filterAttrs (_: v: lib.isAttrs v && !(v ? __meta)) attrs;
    in
      leaves // lib.mapAttrsRecursive (path: v: v) nested;

    allModules = collectModules libInstance;

    # Create bash script to generate symlinks
    script = ''
      #!/usr/bin/env bash
      set -euo pipefail

      SRC="$1"
      DEST="$2"

      echo "Generating documentation symlinks..."
      echo "Source: $SRC"
      echo "Destination: $DEST"

      # Function to create symlink for a module
      link_module() {
        local module_path="$1"
        local module_name="$2"
        local doc_source="$3"

        # Calculate relative path
        local rel_dir="''${module_path#$SRC/}"
        rel_dir="''${rel_dir%/*}"

        # Create destination directory
        local dest_dir="$DEST/$rel_dir"
        if [ "$4" = true ] && [ ! -d "$dest_dir" ]; then
          mkdir -p "$dest_dir"
        fi

        # Destination file
        local dest_file="$dest_dir/$module_name.md"

        # Create symlink if source exists
        if [ -e "$doc_source" ] && [ ! -e "$dest_file" ]; then
          ln -sf "$doc_source" "$dest_file"
          echo "  ✓ $dest_file -> $doc_source"
        elif [ -e "$dest_file" ]; then
          echo "  • $dest_file (already exists)"
        else
          echo "  ✗ $doc_source (source not found)"
        fi
      }
    '';

    # Add commands for each module with documentation
    commands =
      mapAttrsToList (
        path: module:
          if module ? __meta && module.__meta.docs.available && module.__meta.docs.type == "markdown"
          then ''
            link_module "${module.__meta.path}" \
                        "${module.__meta.name}" \
                        "${module.__meta.docs.source}" \
                        "${toString createMissingDirs}"
          ''
          else ""
      )
      allModules;

    fullScript = script + builtins.concatStringsSep "\n" (lib.filter (s: s != "") commands);
  in
    fullScript;

  # Create a documentation index
  createIndex = {dest ? "Documentation/README.md"}: let
    libInstance = (import ./default.nix) {inherit lib;};

    collectModules = attrs: let
      leaves = filterAttrs (_: v: v ? __meta) attrs;
      nested = filterAttrs (_: v: lib.isAttrs v && !(v ? __meta)) attrs;
    in
      leaves // lib.mapAttrsRecursive (path: v: v) nested;

    allModules = collectModules libInstance;

    # Group modules by category
    modulesByCategory =
      lib.mapAttrsToList (
        path: module:
          if module ? __meta
          then let
            # Extract category from path (e.g., "generators.firefox" -> "generators")
            parts = lib.splitString "." path;
            category =
              if lib.length parts > 1
              then lib.head parts
              else "uncategorized";
          in {
            inherit category path module;
          }
          else null
      )
      allModules;

    # Filter out null and group
    validModules = lib.filter (m: m != null) modulesByCategory;
    grouped = lib.groupBy (m: m.category) validModules;

    # Generate markdown
    indexContent = ''
      # Library Documentation Index

      This documentation is automatically generated from the library modules.

      ## Modules by Category

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (category: modules: ''
          ### ${lib.strings.toUpper (lib.strings.substring 0 1 category)}${lib.strings.substring 1 (lib.stringLength category) category}

          ${lib.concatStringsSep "\n" (lib.map (
              m: let
                meta = m.module.__meta;
                docLink =
                  if meta.docs.available && meta.docs.type == "markdown"
                  then "[${m.path}](${lib.removePrefix "Documentation/" (toString meta.docs.source)})"
                  else m.path;
              in "- **${docLink}**: ${
                if meta.docs.available
                then "📚"
                else "❌"
              }"
            )
            modules)}
        '')
        grouped)}

      ## Documentation Sources

      Documentation can be found in multiple locations:

      1. **Co-located with module**: `${moduleName}.md` or `README.md` in the same directory
      2. **Documentation tree**: `Documentation/${path}/${moduleName}.md` (symlinked from source)
      3. **Module `__doc` attribute**: Inline documentation in the Nix file

      ## Last Updated

      Generated on ${builtins.toString (builtins.currentTime)}
    '';
  in
    indexContent;
}
