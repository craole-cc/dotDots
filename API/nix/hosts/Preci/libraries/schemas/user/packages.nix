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
  in {
    inherit names groups;
    expanded = unique (expandNames {inherit groups names;});
    packages = resolvePackageGroups {
      inherit pkgs groups names;
      context = "resolve user '${user.name}'";
    };
  };
in {
  inherit default resolve resolvePackages;
  resolveUserPackages = resolvePackages;
}
