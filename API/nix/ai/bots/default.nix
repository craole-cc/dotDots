{
  lix,
  homeDirectory,
  homePath,
  definitions ? {
    receptionist = ./receptionist;
    coordinator = ./coordinator;
    developer = ./developer;
    librarian = ./librarian;
    anthropologist = ./anthropologist;
    assistant = ./assistant;
    architect = ./architect;
    scribe = ./scribe;
    intern = ./intern;
    auditor = ./auditor;
  },
  enabled,
  default ? "receptionist",
}: let
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.attrsets.transformation) concatMapAttrs;
  inherit (lix.filesystem.access) readDir;
  inherit (lix.filesystem.predicates) pathExists;
  inherit (lix.lists.selection) filter;
  inherit (lix.lists.predicates) elem;
  files = prefix: directory:
    concatMapAttrs (name: kind:
      if kind == "directory"
      then files "${prefix}/${name}" (directory + "/${name}")
      else {"${prefix}/${name}" = directory + "/${name}";}) (readDir directory);
  load = name: let
    definition = definitions.${name};
    directory =
      if pathExists (definition + "/default.nix")
      then definition
      else dirOf definition;
    bot = import definition {inherit lix homeDirectory homePath;};
    skills =
      if pathExists (directory + "/skills")
      then files "skills" (directory + "/skills")
      else {};
  in
    bot
    // {
      home =
        (bot.home or {})
        // {
          file = skills // (bot.home.file or {});
        };
    };
  root = load default;
in
  assert elem default enabled;
    root
    // {
      profiles =
        genAttrs (filter (name: name != default) enabled) (name:
          {bot.enable = true;} // load name);
    }
