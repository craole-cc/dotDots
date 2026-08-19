args: let
  inherit (args) flake pkgs lix inputs paths;
  inherit (args.lix.sources.packages) pkgOf pkgsFrom;
  inherit (lix.lists.construction) optionals;
  inherit (lix.modules.core.software) mkFetch;
  inherit (lix.strings.construction) concat;
  inherit (pkgs) writeShellScriptBin writeShellApplication;
  inherit (pkgs.stdenv.hostPlatform) system isLinux isDarwin;

  fetch = mkFetch {
    inherit pkgs paths;
    inherit (flake) name;
  };

  cmdExists = writeShellScriptBin "cmd-exists" ''
    command -v "$@" >/dev/null 2>&1
  '';

  mkName = name: "${flake.name}-${name}";

  pkgFor = {
    input ? null,
    target ? null,
    required ? true,
  }:
    pkgOf {inherit input inputs pkgs required target;};

  pkgsFor = {
    sources,
    required ? true,
    exclude ? [],
  }:
    pkgsFrom {inherit inputs pkgs required sources exclude;};

  print = let
    package = pkgFor {target = "gum";};
    inherit (package) exe;
  in {
    inherit exe package;

    title = text: ''
      ${exe} style \
        --bold \
        --margin "1 0" \
        "${text}"
    '';

    subtitle = text: ''
      ${exe} style \
        --bold \
        --margin "0 1" \
        "${text}"
    '';

    list = values: ''
      ${exe} style \
        --margin "0 2" \
        "${concat "\n" values}"
    '';

    table = {
      columns,
      rows,
    }: let
      data = concat "\n" (map (row: concat "," row) rows);
    in ''
      ${exe} table \
        --print \
        --columns "${concat "," columns}" \
        --separator "," <<EOF
      ${data}
      EOF
    '';

    info = text: ''
      ${exe} style \
        --margin "1 0" \
        ">> ${text} <<"
    '';
  };
in
  args
  // {
    inherit
      cmdExists
      fetch
      isDarwin
      isLinux
      mkName
      optionals
      pkgFor
      pkgsFor
      print
      system
      writeShellApplication
      writeShellScriptBin
      ;
  }
  // pkgsFor {
    sources = {
      gawk = null;
      git = null;
    };
  }
