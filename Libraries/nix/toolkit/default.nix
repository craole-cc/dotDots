# Pure data + group derivation. No nixpkgs needed.
let
  inherit (builtins) attrNames concatMap filter listToAttrs;

  sources = import ./sources.nix;
  aliases = import ./aliases.nix;
  prefer = import ./prefer.nix;

  names = attrNames sources;

  groupOf = name:
    sources.${name}.group
    or (throw "toolkit: source '${name}' has no `group`");

  # Plain groups come straight from the tags on each source.
  groupNames = attrNames (listToAttrs (map (n: {
      name = groupOf n;
      value = null;
    })
    names));

  plain = listToAttrs (map (g: {
      name = g;
      value = filter (n: groupOf n == g) names;
    })
    groupNames);

  # Composites are lists of plain group names, nothing else.
  composites = {
    desktop = ["desktop-cli" "desktop-ui"];
    scripting = ["core" "files" "shells" "system" "text" "networking" "archives" "desktop-cli"];
  };

  expand = cname: gs:
    concatMap (g:
      plain.${g}
      or (throw "toolkit: composite '${cname}' references unknown group '${g}'"))
    gs;

  resolved = builtins.mapAttrs expand composites;

  clash = filter (c: plain ? ${c}) (attrNames composites);
in
  assert clash == [] || throw "toolkit: composite names shadow plain groups: ${toString clash}"; {
    inherit sources aliases prefer;
    groups = plain // resolved // {all = names;}; # name lists, not specs
  }
