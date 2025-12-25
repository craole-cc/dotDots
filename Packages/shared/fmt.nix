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
    rustfmt
    shellcheck
    shfmt
    stylua
    taplo
    typstyle
    yamlfmt
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

      # Just use --fail-on-change, remove the diff comparison
      ${treefmtWrapper}/bin/treefmt --no-cache --fail-on-change

      cd /
      rm -rf $TMPDIR
      touch $out
    '';
}
