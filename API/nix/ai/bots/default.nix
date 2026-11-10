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
  environmentFiles ? [],
  default ? "receptionist",
}: let
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.transformation) concatMapAttrs;
  inherit (lix.filesystem.access) readDir;
  inherit (lix.filesystem.predicates) pathExists;
  inherit (lix.lists.selection) filter;
  inherit (lix.lists.transformation) unique;
  inherit (lix.lists.predicates) elem;
  files = prefix: directory:
    concatMapAttrs (name: kind:
      if kind == "directory"
      then files "${prefix}/${name}" (directory + "/${name}")
      else {"${prefix}/${name}" = directory + "/${name}";}) (readDir directory);
  delegationProfiles = map (name: {
    inherit name;
    description = (load name).description or "Run a bounded task as ${name}.";
  }) (filter (name: name != default && name != "coordinator") enabled);
  load = name: let
    definition = definitions.${name};
    directory =
      if pathExists (definition + "/default.nix")
      then definition
      else dirOf definition;
    declared = import definition {inherit lix homeDirectory homePath environmentFiles delegationProfiles;};
    fallback =
      if elem name ["developer" "architect" "auditor" "librarian" "anthropologist" "assistant" "intern" "scribe"]
      then
        import ../routing/fallback.nix {
          inherit lix homePath;
          profile = name;
        }
      else {};
    capability = import ./capabilities.nix {
      inherit lix homePath;
      role = name;
    };
    bot = recursiveUpdate (recursiveUpdate declared fallback) capability;
    skills =
      if pathExists (directory + "/skills")
      then files "skills" (directory + "/skills")
      else {};
  in
    bot
    // {
      environment =
        (bot.environment or {})
        // {files = unique (environmentFiles ++ (bot.environment.files or []));};
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
      profiles = genAttrs (filter (name: name != default) enabled) (name: let
        profile = load name;
      in
        profile
        // {
          bot = {enable = true;} // (profile.bot or {});
        });
    }
