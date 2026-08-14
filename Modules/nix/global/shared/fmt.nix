{
  lix,
  paths,
  pkgFor,
  pkgs,
  ...
}: let
  inherit (paths) src;
  inherit (pkgs) writeShellScriptBin runCommand;
  inherit (lix.sources.access) getExe;
  inherit (lix.sources.transformation) makeBinPath;

  treefmt = {inherit (pkgFor {input = "treefmt-nix";}) pkg exe;};

  buildInputs =
    [treefmt.pkg]
    ++ (with pkgs; [
      actionlint
      alejandra
      deno
      dos2unix
      leptosfmt
      markdownlint-cli2
      nixfmt
      prettierd
      rustfmt
      shellcheck
      shfmt
      statix
      stylua
      tombi
      typstyle
      yamlfmt
    ]);

  formatter = writeShellScriptBin "treefmt" ''
    export PATH=${makeBinPath buildInputs}:$PATH
    exec ${treefmt.exe} "$@"
  '';
in {
  inherit formatter;
  formatters = buildInputs ++ [formatter];
  checks.formatting = runCommand "check-formatting" {inherit buildInputs;} ''
    sh ${./fmt.sh} ${src} ${getExe formatter} "$out"
  '';
}
