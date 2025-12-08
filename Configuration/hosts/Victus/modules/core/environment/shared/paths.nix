{
  lib,
  pkgs,
  host,
  ...
}: let
  inherit (builtins) path;
  inherit (lib.attrsets) attrByPath;
  inherit (lib.modules) mkIf;
  inherit (lib.lists) optional;
  inherit (lib.strings) toUpper;
  inherit (pkgs.stdenv) mkDerivation;

  prefix = toUpper host.name + "_";

  paths = {
    cfg = attrByPath ["base" "absolute"] null host.paths;
    bin = attrByPath ["binaries" "base" "absolute"] null host.paths;
  };

  binPath = with paths;
    if bin != null
    then bin
    else "/home/craole/Configuration/bin";

  #~@ Create a package that adds symlinks to all scripts
  binPackage = mkDerivation {
    name = "${host.name}-scripts";

    src = path {
      path = ../../../../bin;
      name = "scripts-source";
    };

    installPhase = ''
      mkdir -p $out/bin

      # Find all executable files, excluding patterns
      find . -type f -executable \
        ! -name "*.nix" \
        ! -name "* copy*" \
        ! -path "*/archive/*" \
        ! -path "*/review/*" \
        ! -path "*/tmp/*" \
        ! -path "*/temp/*" \
        -print0 | while IFS= read -r -d "" script; do

      # Get the script name
      name=$(basename "$script")

      # Create a wrapper that runs the original script
      cat > "$out/bin/$name" << EOF

      #!/bin/sh
      exec "${binPath}/$script" "\$@"
      EOF
            chmod +x "$out/bin/$name"
        done
    '';

    meta = {
      description = "Script wrappers for ${host.name}";
    };
  };
in
  with paths; {
    environment = mkIf (cfg != null) {
      sessionVariables = {
        "${prefix}CONFIG" = cfg;
        "NIXOS_CONFIG" = cfg;
        "NIXOS_FLAKE" = cfg;
        "${prefix}BIN" = mkIf (bin != null) bin;
      };

      systemPackages = optional (bin != null) binPackage;
    };
  }
