{
  pkgs,
  flake,
}: let
  inherit (pkgs.lib) makeBinPath;
  inherit (pkgs) writeShellScriptBin runCommand;

  formatters = with pkgs; [
    actionlint
    alejandra
    deno
    dos2unix
    markdownlint-cli2
    shellcheck
    shfmt
    stylua
    taplo
    yamlfmt
    rustfmt
  ];

  formatterPath = makeBinPath formatters;
  treefmtWrapper = writeShellScriptBin "treefmt" ''
    export PATH=${formatterPath}:$PATH
    # export TREEFMT_NO_CACHE=1
    exec ${pkgs.treefmt}/bin/treefmt "$@"
  '';
in {
  formatters = formatters ++ [treefmtWrapper];
  formatter = treefmtWrapper;
  checks.formatting =
    runCommand "check-formatting" {
      buildInputs = formatters;
    } ''
      export TMPDIR=$(mktemp -d)
      cd $TMPDIR

      cp -r ${flake}/* .
      chmod -R +w .

      for config in shellcheckrc .shellcheckrc treefmt.toml .treefmt.toml rustfmt.toml .rustfmt.toml markdownlint.yaml .markdownlint.yaml typos.toml .typos.toml; do
        if [ -f ${flake}/$config ]; then
          cp ${flake}/$config .
          chmod +w $config 2>/dev/null || true
        fi
      done

      # Format once without checking, then check if anything changed
      ${treefmtWrapper}/bin/treefmt --no-cache

      # Now check if files differ from source
      if ! diff -r . ${flake} > /dev/null 2>&1; then
        echo "Formatting differences detected. Run 'nix fmt' to fix."
        exit 1
      fi

      cd /
      rm -rf $TMPDIR
      touch $out
    '';
}
