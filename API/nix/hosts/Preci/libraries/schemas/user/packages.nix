{lix, ...}: let
  inherit (lix.attrsets) recursiveUpdate;
  inherit (lix.lists) unique;
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

  resolveUserPackages = {
    user,
    pkgs,
  }: let
    inherit (user.packages) shells common launchers;
    groups = {inherit shells common launchers;};
    names = unique (common ++ launchers ++ shells);
  in {
    inherit names;
    expanded = unique (expandNames {inherit groups names;});
    packages = resolvePackageGroups {
      inherit pkgs groups names;
      context = "resolve user '${user.name}'";
    };
  };
in {inherit default resolve resolveUserPackages;}
