args: let
  inherit (args) lix paths pkgFor pkgs;
  inherit (paths) src;
  inherit (pkgs) writeShellScriptBin runCommand;
  inherit (lix.sources.access) getExe;
  inherit (lix.sources.transformation) makeBinPath;

  treefmt = pkgFor {
    input = "treefmt-nix";
    target = "treefmt";
  };

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
  checks.formatting = runCommand "lint" {inherit buildInputs;} ''
    sh ${./fmt.sh} ${src} ${getExe formatter} "$out"
  '';
}
