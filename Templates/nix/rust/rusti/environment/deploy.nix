{
  lib,
  templates,
}: let
  inherit (lib.strings) concatStringsSep;

  mkDeploy = {pkgs ? null}: let
    inherit (pkgs) writeShellScriptBin;

    deployTemplates = writeShellScriptBin "deploy-templates" (concatStringsSep "\n" [
      "set -euo pipefail"
      ''ROOT="''${PRJ_ROOT:-$PWD}"''
      ''
        #> Color helpers via gum
        green()  { ${pkgs.gum}/bin/gum style --foreground 82 "$@"; }
        yellow() { ${pkgs.gum}/bin/gum style --foreground 226 "$@"; }
        info()   { ${pkgs.gum}/bin/gum style --foreground 250 "$@"; }
      ''
      ''
        #> Template definitions
        declare -A TEMPLATES=(
          ["${templates.cargo}"]=".cargo/config.toml"
          ["${templates.envrc}"]=".envrc"
          ["${templates.gitignore}"]=".gitignore"
          ["${templates.markdownlint}"]=".markdownlint-cli2.yaml"
          ["${templates.mise}"]=".mise.toml"
          ["${templates.rust-analyzer}"]="rust-analyzer.toml"
          ["${templates.rust-toolchain}"]="rust-toolchain.toml"
          ["${templates.rustfmt}"]="rustfmt.toml"
          ["${templates.shellcheck}"]=".shellcheckrc"
          ["${templates.treefmt}"]=".treefmt.toml"
        )
      ''
      ''
        #> Ensure target directory exists
        mkdir -p "$ROOT/.cargo"
      ''
      ''
        #> Deploy each template
        for source in "''${!TEMPLATES[@]}"; do
          target="''${TEMPLATES[$source]}"
          full_target="$ROOT/$target"
          full_source="$source"
      ''
      ''
        #> Ensure target directory exists
        mkdir -p "$(dirname "$full_target")"
      ''
      ''
          #> Deploy if missing or changed
          if [ ! -f "$full_target" ]; then
            green "Deploying $target"
            cp "$full_source" "$full_target"
            chmod u+w "$full_target"
          elif ! cmp -s "$full_source" "$full_target"; then
            info "Updating $target"
            cp "$full_source" "$full_target"
            chmod u+w "$full_target"
          else
            info "Already up-to-date: $target"
          fi
        done
      ''
      ''
        #> Handle mise.toml -> .mise.toml migration
        if [ -f "$ROOT/mise.toml" ] && [ ! -f "$ROOT/.mise.toml" ]; then
          yellow "Migrating mise.toml → .mise.toml"
          mv "$ROOT/mise.toml" "$ROOT/.mise.toml"
        fi
      ''
      ''
        #> Handle markdownlint-cli2.yaml migration
        if [ -f "$ROOT/markdownlint-cli2.yaml" ] && [ ! -f "$ROOT/.markdownlint-cli2.yaml" ]; then
          yellow "Migrating markdownlint-cli2.yaml → .markdownlint-cli2.yaml"
          mv "$ROOT/markdownlint-cli2.yaml" "$ROOT/.markdownlint-cli2.yaml"
        fi
      ''
      ''
        #> Handle treefmt.toml migration
        if [ -f "$ROOT/treefmt.toml" ] && [ ! -f "$ROOT/.treefmt.toml" ]; then
          yellow "Migrating treefmt.toml → .treefmt.toml"
          mv "$ROOT/treefmt.toml" "$ROOT/.treefmt.toml"
        fi
      ''
      ''
        #> Remove cached files from git
        git rm -r --cached .direnv target 2>/dev/null || true
      ''
      "green \"Templates deployed successfully!\""
    ]);

    mkInit = writeShellScriptBin "init" (concatStringsSep "\n" [
      "set -euo pipefail"
      ''
        #> Deploy templates
        deploy-templates
      ''
      ''
        #> Make files writable
        chmod +w .envrc .gitignore .treefmt.toml .markdownlint-cli2.yaml .mise.toml 2>/dev/null || true
      ''
      ''
        #> Remove old cached files from git staging
        git rm -r --cached .direnv target 2>/dev/null || true
      ''
      ''
        #> Allow direnv if needed
        if ! direnv status 2>/dev/null | grep -q "Found RC allowed"; then
          if gum confirm "Allow direnv?"; then
            direnv allow .envrc 2>/dev/null || true
          fi
        fi
      ''
      "direnv reload"
    ]);
  in {inherit deployTemplates mkInit;};
in {inherit mkDeploy;}
