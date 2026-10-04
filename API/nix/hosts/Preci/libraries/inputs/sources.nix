{
  lix,
  sources,
  inputs ? lix.inputs or null,
  ...
}: let
  inherit (lix.attrsets) mapAttrs;
  inherit (lix.fetchers) materialiseSource mkGitHubSource;

  resolveSource = name: spec: let
    type = spec.type or (throw "sources.${name}: missing 'type'");
    arguments = removeAttrs spec ["type"];
  in
    if inputs ? ${name}
    then let
      flakeInput = inputs.${name};
    in
      arguments
      // {
        fromFlake = true;
        path = flakeInput.outPath or flakeInput;
        value = flakeInput;
      }
    else if type == "github"
    then (materialiseSource (mkGitHubSource arguments)) // {fromFlake = false;}
    else if type == "pin"
    then arguments // {fromFlake = false;}
    else throw "sources.${name}: unknown type '${type}'";
in
  mapAttrs resolveSource sources
