{
  lix,
  host,
  principals,
  ...
}: let
  inherit (lix) modules;
  inherit (lix.attrsets) attrNames attrValues filterAttrs genAttrs mapAttrs;
  inherit (lix.lists) concatLists elem filter isList;
  inherit (lix.strings) aliasOf slugify;

  #? The module groups this context gates.
  groups = ["core" "home"];

  #? What a principal asked for, by name.
  #?
  #? Two vocabularies, both read, because the same intent arrives in either:
  #?
  #?   capabilities  a name per *capability* -- `management`, `gaming`. This is
  #?                 the request vocabulary proper.
  #?
  #?   packages      a name per *package group* whose value is a list of
  #?                 package names -- `ai-agent = ["hermes"]`. The group name
  #?                 says nothing; `hermes` inside it is the request. Reading
  #?                 only the keys would find `ai-agent`, which no module is
  #?                 named after, and miss every actual request.
  #?
  #? So package groups are flattened to their contents. `encoding` and `meta`
  #? are dropped for the reason `resolvePackages` drops them: they describe how
  #? to resolve a name rather than being names.
  namesOf = value:
    attrNames (removeAttrs (
      if value == null
      then {}
      else value
    ) ["encoding" "meta"]);

  packagesOf = value: let
    packageGroups = namesOf value;
  in
    packageGroups
    ++ concatLists (
      map (packageGroup:
        if isList value.${packageGroup}
        then value.${packageGroup}
        else [])
      packageGroups
    );

  #? Absent `capabilities` or `packages` mean "asked for nothing", not an error.
  requestedOf = user:
    namesOf (user.capabilities or null)
    ++ packagesOf (user.packages or null);

  #? Union across principals, in declared order, so the primary user's
  #? preferences lead -- the priority rule `interface.nix` applies to desktops.
  #? Order changes only the order things are reported in, not which modules end
  #? up enabled.
  #?
  #? A union, not an intersection: `services.hermes-agent` is a systemd service,
  #? so one principal asking for it makes it available to the host. Enabling it
  #? per-principal would mean a system service scoped to one account, which is
  #? not the thing it is.
  #?
  #? A host asks by naming a package group, the way a principal does.
  requested =
    concatLists (map requestedOf (attrValues principals))
    ++ packagesOf (host.packages or null);

  #? The sources of every alias a request resolves to.
  #?
  #? An alias is followed one hop and compared on its *source*: `hermes` aliases
  #? to `{source = "hermes-agent", name = "default"}`, and a module is reached
  #? through the source it draws from. `(…)?` is not Nix syntax, so the null that
  #? `aliasOf` returns for an unknown name is filtered out explicitly.
  #?
  #? Depends only on `requested`, so it is computed once rather than per module.
  slugs = {
    requested = map slugify requested;
    aliased = map slugify (
      filter (source: source != null) (
        map (
          request: let
            entry = aliasOf request;
          in
            if entry == null
            then null
            else entry.source
        )
        requested
      )
    );
  };

  #? Whether a request names this module.
  #?
  #? Three spellings are compared, and they answer different questions:
  #?
  #?   exact        `hermes-agent` matches `hermes-agent` -- the entry is named
  #?                after the thing it provides.
  #?
  #?   slugified    `Hermes` matches `hermes`, `zen_twilight` matches
  #?                `zen-twilight`. This is *shape*: safe, because it only
  #?                ignores how the author cased and separated it.
  #?
  #?   aliased      `hermes` matches `hermes-agent`, because the alias table says
  #?                the user says `hermes` and means this. That is a
  #?                *judgement* about one name and cannot be derived --
  #?                `slugify "hermes"` is `"hermes"`, not `"hermes-agent"`. Two
  #?                spellings differing by a suffix are the same thing far too
  #?                often to guess at (`linux` / `linuxPackages`) and far too
  #?                rarely to always join (`brave` / `brave-bin`), so the table
  #?                decides and nothing else does.
  #?
  #? Both the direct and the aliased path compare slugified names, so a module's
  #? own casing and separators never decide whether it is reached.
  askedFor = name: let
    asSlug = slugify name;
  in
    elem asSlug slugs.requested || elem asSlug slugs.aliased;

  #? Whether a registry entry is unconditional.
  #?
  #? Read from `lix.registry`, not from `modules`. `libraries/inputs/modules.nix`
  #? strips `always` before calling `fetchModule`, because it is a registry
  #? marker rather than an argument the fetcher accepts -- so the resolved group
  #? cannot report it, and reading it there silently yields `false` for every
  #? entry, which un-gates `sops` and `catppuccin` and breaks the host.
  #?
  #? `always` entries are unconditional -- they declare options the host tree
  #? reads (`config.sops`, `catppuccin.flavor`), so omitting one is a broken
  #? host rather than a leaner one. Everything else is a candidate, imported
  #? only when something named it.
  alwaysOf = group: name:
    lix.registry.modules.${group}.${name}.always or false;

  #? Per registry name: whether this module is imported on this host.
  #?
  #? Valued `true` rather than the module itself, so this is a *gate*: a reader
  #? wanting the modules filters `lix.modules.<group>` by it, and a reader only
  #? wanting the answer reads the bool. Two views of one decision, so a module
  #? tree and a service module cannot disagree about what was requested.
  gate = group:
    mapAttrs (
      name: _: alwaysOf group name || askedFor name
    )
    modules.${group};

  #? Per group, per registry name, `true` when imported on this host.
  enabled = genAttrs groups gate;

  #? The resolved modules of one group, gated.
  #?
  #? Reads `enabled` rather than calling `gate` again, so the decision is made
  #? once and every view of it agrees. `filterAttrs` keeps attribute-name order.
  filtered = group:
    attrValues (
      filterAttrs
      (name: _: enabled.${group}.${name})
      modules.${group}
    );

  #? The modules each group should import, gated. `default.nix` and
  #? `modules/home/default.nix` consume these.
  imports = genAttrs groups filtered;

  #? A module that was asked for and is now imported, which is worth saying out
  #? loud because the other half -- its own `enable` -- is not checkable here.
  #?
  #? Nothing here can read a module's internal `enable`; that is the module's
  #? business, and the option system reports it at build time. So this says the
  #? request reached the gate and the gate imported the module. A host asking
  #? for `hermes` and getting no service has usually forgotten the second half.
  #?
  #? `always` modules are skipped: nobody asked for them, so there is nothing to
  #? remind anyone about.
  warnings = concatLists (
    map (
      group:
        map (
          name: "context modules (${group}): '${name}' was requested and is imported; if its service is still absent, nothing has set its enable option"
        ) (
          filter (
            name:
              enabled.${group}.${name} && !(alwaysOf group name)
          ) (attrNames enabled.${group})
        )
    )
    groups
  );
in {inherit enabled imports requested warnings;}
