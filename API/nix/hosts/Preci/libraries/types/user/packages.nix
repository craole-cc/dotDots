{lix, ...}: let
  inherit (lix.attrsets) attrValues recursiveUpdate removeAttrs;
  inherit (lix.lists) concatLists unique;
  inherit (lix.packages) expandNames resolvePackageGroups;

  default = {
    agent = [];
    bar = [];
    browser = ["brave"];
    common = [];
    editor = ["helix"]; # TTY editor
    explorer = [];
    extra = [];
    ide = ["vscode-fhs"]; # GUI
    launcher = ["vicinae"];
    prompt = ["starship"];
    shell = ["bash"];
    terminal = ["ghostty "];
  };

  resolve = args:
    recursiveUpdate default (args.packages or {});

  resolvePackages = {
    user,
    pkgs,
    #? Forwarded to `resolvePackageGroups`: the fetched package sets and flakes a
    #? name might live in, keyed by source, and the alias table that maps a
    #? requested spelling to the pool and name its source actually publishes.
    #? Without these, any name outside nixpkgs -- `hermes`, `zen-twilight` -- is
    #? reported absent even though the source publishing it is already pinned in
    #? the registry.
    #?
    #? Keyed, not a list: an alias pins a *pool*, and nixpkgs publishes its own
    #? `chatgpt`, so renaming alone would still find the darwin-only one.
    #?
    #? Named `pools`, not `extra`: `extra` is a package *group* -- craole's spec
    #? declares one -- and a parameter of that name shadowed the group inside this
    #? function, so the pools were expanded as though they were package names and
    #? the pool attrset came back as one of the requested names.
    pools ? {},
    aliasOf ? name: null,
  }: let
    #? The groups are whatever the user declared, not a fixed three.
    #?
    #? Reading `user.packages` directly rather than naming groups means the
    #? resolver cannot fall out of step with the spec: this used to `inherit`
    #? `shells`, `common` and `launchers`, but the schema and the spec both
    #? declare `shell`, `browser`, `ai-agent`, `editor` and the rest in the
    #? singular -- so every real principal threw on `launchers`, and any group
    #? added to the spec was silently ignored.
    #?
    #? `encoding` and `meta` are dropped when present: they describe how to
    #? resolve a name rather than being groups of names themselves, so
    #? expanding them as groups would pass their keys to the package set.
    groups = removeAttrs (user.packages or {}) ["encoding" "meta"];

    names = unique (concatLists (attrValues groups));
    resolution = resolvePackageGroups {
      inherit pkgs groups names aliasOf;
      extra = pools;
      context = "resolve user '${user.name}'";
    };
  in {
    inherit names groups;
    expanded = unique (expandNames {inherit groups names;});

    #? Names no pool carried, and the warning about them. Dropped rather than
    #? failing the build -- see the note on `resolvePackageGroups`. A principal
    #? asking for a tool that does not exist should still get a working profile.
    inherit (resolution) missing warnings;

    packages = resolution.packages;
  };
in {
  inherit default resolve resolvePackages;
  resolveUserPackages = resolvePackages;
}
