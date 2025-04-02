{
  flakePath ? null,
  hostnamePath ? "/etc/hostname",
  registryPath ? "/etc/nix/registry.json",
}:
let
  inherit (builtins)
    getFlake
    head
    elemAt
    length
    match
    currentSystem
    readFile
    pathExists
    filter
    fromJSON
    ;

  selfFlake =
    if pathExists registryPath then
      filter (f: f.from.id == "self") (fromJSON (readFile registryPath)).flakes
    else
      [ ];

  flakePath' = toString (
    if flakePath != null then
      flakePath
    else if selfFlake != [ ] then
      (head selfFlake).to.path
    else
      "/etc/nixos"
  );

  flake = if pathExists flakePath' then flakePath' else { };

  hostname =
    if pathExists hostnamePath then
      let
        m = match "([a-zA-Z0-9\\-]+)\n" (readFile hostnamePath);
      in
      if m != null then head m else ""
    else
      "";

  findFirstPath =
    {
      index ? 0,
      names ? [ ],
      inputs ? null,
    }:
    if names == [ ] || index >= length names then
      throw "No possible inputs defined"
    else
      let
        name = elemAt names index;
      in
      if inputs ? "${name}" then inputs."${name}".outPath else findFirstPath (index + 1);

  pkgsFromInputsPath =
    let
      path = findFirstPath {
        inherit (flake) inputs;
        names = [
          "nixpkgs"
          "nixPackages"
          "nixpkgsUnstable"
          "nixpkgsStable"
          "nixpkgs-unstable"
          "nixpkgs-stable"
          "nixosPackages"
          "nixosUnstable"
          "nixosStable"
        ];
      };
    in
    if path != "" then import path { } else null;

  nixpkgs = flake.pkgs.${currentSystem}.nixpkgs or pkgsFromInputsPath;
  nixpkgsOutput = removeAttrs (nixpkgs // (nixpkgs.lib or { })) [
    "options"
    "config"
  ];
in
{
  inherit flake;
}
// flake
// builtins / (flake.nixosConfigurations or { })
// flake.nixosConfigurations.${hostname} or { }
// nixpkgsOutput
// {
  getFlake = path: getFlake (toString path);
}
