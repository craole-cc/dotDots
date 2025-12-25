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
    yamlfmt
  ];

  formatterPath = makeBinPath formatters;
  treefmtWrapper = writeShellScriptBin "treefmt" ''
    export PATH=${formatterPath}:$PATH
    exec ${pkgs.treefmt}/bin/treefmt "$@"
  '';
in {
  formatters = formatters ++ [treefmtWrapper];
  formatter = treefmtWrapper;
  checks = {
    formatting =
      runCommand "check-formatting" {
        buildInputs = formatters;
      } ''
        cd ${flake}
        ${treefmtWrapper}/bin/treefmt --fail-on-change
        touch $out
      '';
  };
}
