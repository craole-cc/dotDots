{_, ...}: let
  meta = let
    doc = ''
      # Toolkit Sources

      Builds a host-specific toolkit from package sources and aliases.

      ## Functions

      - `mkToolkit` - resolves sources and builds toolkit packages, binaries, and helpers
      - `mkAliases` - renders aliases against resolved binaries
      - `preferFrom` - maps preferred binaries to their source names
      - `registry` - describes toolkit source and alias registries
      - `mergeDisjoint` - merges attribute sets while rejecting duplicate keys

    '';
    exports = {
      local = {inherit registry mkToolkit mkAliases preferFrom mergeDisjoint;};
      alias = {};
    };
  in {inherit doc exports;};
  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.aggregation) intersectAttrs mergeDisjoint recursiveUpdate;
  inherit (_.attrsets.construction) genAttrs listToAttrs optionalAttrs;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.lists.access) head tail;
  inherit (_.lists.aggregation) concatMap;
  inherit (_.lists.construction) optional;
  inherit (_.lists.predicates) elem;
  inherit (_.lists.transformation) filter;
  inherit (_.sources.packages) pkgsFrom mkAll;
  inherit (_.sources.transformation) cleanSource cleanSourceWith fileset;
  inherit (_.strings.construction) concat;
  inherit (_.strings.transformation) escapeShellArgs;
  inherit (_.types.predicates) isList;

  #~@ Data
  #? Keys that are ours, not `pkgsFrom`'s.
  ownKeys = ["name" "categories" "description" "prefer" "aliases"];
  mkCategories = categories:
    if isList categories
    then concatMap mkCategories categories
    else optional (categories != null) categories;

  defaults = with registry; {
    sources = sources.entries;
    aliases = aliases.entries;
    prefer = recursiveUpdate prefer {
      kill = "procps";
      uptime = "procps";
    };
  };

  registry = let
    tools = import ./data/toolkit.nix;
    describe = entries: {
      inherit entries;
      names = attrNames entries;
    };
    sources = describe (
      mapAttrs (
        name: source:
          recursiveUpdate {
            inherit name;
            categories = [];
            prefer = [];
          }
          (source // {categories = mkCategories (source.categories or []);})
      )
      tools
    );
  in {
    /**
    Sources are tagged with `categories`; every category is a group, so there
    are no separate composites (`scripting` and `desktop` are just categories).
    `prefer` lists the binaries this source wins when several packages ship
    the same one.
    */
    inherit sources;
    aliases = describe (mergeDisjoint {
      context = "toolkit aliases";
      sets = map (sourceName: tools.${sourceName}.aliases or {}) (attrNames tools);
    });
    prefer = preferFrom sources.entries;
  };

  #? Name lists, not specs.
  categories = let
    reg = registry.sources;
    names = attrNames (listToAttrs (
      map (name: {
        inherit name;
        value = null;
      })
      (concatMap (name: reg.entries.${name}.categories) reg.names)
    ));
  in
    assert !(elem "all" names)
    || throw "toolkit: 'all' is reserved, it cannot be a category";
      {all = reg.names;}
      // listToAttrs (
        map (name: {
          inherit name;
          value =
            filter
            (source: elem name reg.entries.${source}.categories)
            reg.names;
        })
        names
      );

  #~@ Functions
  # binary -> source that wins it. Two sources claiming one binary is an error.
  preferFrom = set:
    mergeDisjoint {
      context = "toolkit prefer";
      sets = map (
        name:
          listToAttrs (
            map (binary: {
              name = binary;
              value = name;
            })
            set.${name}.prefer
          )
      ) (attrNames set);
    };

  /**
  Render alias specs (`{cmd = [binary arg...]; after? = [[binary arg...]]; description?;}`) against
  resolved binaries. Arguments are shell-escaped. Commands in `after` run
  sequentially after the main command, including when it fails.

  Throws if an alias name shadows a real binary, or if an alias refers to a
  binary that is not among the sources.

  # Type
  ```nix
  mkAliases :: { lib :: AttrSet, binaries :: AttrSet, aliases :: AttrSet } -> AttrSet
  ```
  */
  mkAliases = {
    binaries,
    aliases,
  }: let
    shadowed = attrNames (intersectAttrs binaries aliases);
  in
    assert (shadowed == [])
    || throw "toolkit: alias names shadow real binaries: ${toString shadowed}";
      mapAttrs (aliasName: spec: let
        renderCommand = command: let
          binary = head command;
          path = binaries.${binary} or
            (throw "toolkit alias '${aliasName}': '${binary}' is not in sources");
        in "${path} ${escapeShellArgs (tail command)}";
      in
        concat "; " (map renderCommand ([spec.cmd] ++ (spec.after or []))))
      aliases;

  /**
  Build the toolkit for a given set of inputs and host.

  Caller `sources` replace default entries wholesale, so an override does not
  inherit the default's `categories` and will not appear in `packages.group`.

  # Type
  ```nix
  mkToolkit :: {
    inputs :: AttrSet,
    pkgs? :: AttrSet | null,
    host? :: AttrSet,
    sources? :: AttrSet,
    prefer? :: AttrSet,
    aliases? :: AttrSet,
    enableShorthand? :: bool
  } -> AttrSet
  ```
  */
  mkToolkit = {
    inputs,
    pkgs ? null,
    host ? {},
    sources ? {},
    prefer ? {},
    aliases ? {},
    enableShorthand ? false,
    ...
  }: let
    resolved = {
      pkgs =
        if pkgs != null
        then pkgs
        else (mkAll {inherit inputs host;}).pkgs;

      aliases = defaults.aliases // aliases;
      sources = defaults.sources // sources;
    };
    pkgs' = resolved.pkgs;

    # An emptied spec goes back to `null`, `pkgsFrom`'s "use defaults" form.
    forPkgsFrom = mapAttrs (_sourceName: spec: let
      remaining = removeAttrs spec ownKeys;
    in
      if remaining == {}
      then null
      else remaining);

    derived = pkgsFrom {
      inherit inputs enableShorthand;
      inherit (resolved) pkgs;
      required = true;
      prefer = defaults.prefer // prefer;
      sources = forPkgsFrom resolved.sources;
    };

    binaries = recursiveUpdate derived.binaries (mkAliases {
      inherit (derived) binaries;
      inherit (resolved) aliases;
    });

    defined = let
      pkgsByName = mapAttrs (_name: spec: spec.package) derived.records;
    in
      {
        inherit binaries;
        descriptions =
          derived.descriptions
          // mapAttrs (_: spec: let
            description = spec.description or null;
          in
            if description == null
            then head spec.cmd
            else "${head spec.cmd} - ${description}")
          resolved.aliases;
        packages = recursiveUpdate pkgsByName (recursiveUpdate
          (
            mapAttrs
            (_groupName: members: map (member: pkgsByName.${member}) members)
            categories
          ) {
            all = derived.packages;
            scripting = map (member: pkgsByName.${member}) categories.scripting;
          });
      }
      // (optionalAttrs enableShorthand {bins = binaries;});

    formats =
      genAttrs ["json" "toml" "yaml" "ini"]
      (formatName: pkgs'.formats.${formatName} {});

    helpers = {
      types = recursiveUpdate _.types {
        formats =
          mapAttrs
          (_formatName: format: format.type)
          formats;
      };
      options = _.options.construction;

      builders = {
        inherit (pkgs') applyPatches buildEnv makeBinaryWrapper makeDesktopItem makeShellWrapper replaceVars runCommand runCommandCC runCommandLocal runCommandNoCC symlinkJoin;
      };

      source = {
        inherit cleanSource cleanSourceWith fileset;
      };

      fetch = with pkgs'; {
        fromGit = fetchgit;
        fromGitHub = fetchFromGitHub;
        fromGitLab = fetchFromGitLab;
        fromUrl = fetchurl;
        fromZip = fetchzip;
        patch = fetchpatch;
        tarball = fetchTarball;
      };

      platform = {
        inherit (pkgs'.stdenv.hostPlatform) isAarch64 isLinux isDarwin isx86_64 system;
        shell = pkgs'.runtimeShell;
      };

      write = let
        inherit (pkgs') linkFarm writeShellApplication writeShellScript writeText writeTextFile;
        inherit (pkgs'.writers) writeDash writeDashBin;

        binWith = name: runtimeInputs: text:
          writeShellApplication {inherit name runtimeInputs text;};

        rust = {name, src, inputs ? [], arguments ? []}:
          writeShellApplication {
            inherit name;
            runtimeInputs = [pkgs'.rust-script] ++ inputs;
            text = ''
              exec rust-script ${src} ${builtins.concatStringsSep " " arguments} "$@"
            '';
          };
      in
        {
          #? Package with bin/<name>: strict mode and shellcheck, no PATH assumptions
          bin = name: binWith name [];
          #? Same, with packages added to PATH
          inherit binWith;

          link = linkFarm; #? name, [{name; path;}]
          posix = writeDash; #? POSIX sh file, for ExecStart= and the like
          posixBin = writeDashBin; #? POSIX sh with bin/<name>
          script = writeShellScript; #? bash file, for ExecStart= and the like
          inherit rust;
          text = writeText;
          textFile = writeTextFile; #? supports executable, destination, etc.
        }
        // #> Expose common serializers as well
        mapAttrs (_formatName: format: format.generate) formats;
    };
  in
    mergeDisjoint {
      context = "mkToolkit";
      sets = [
        # These derived values are re-exported via `defined`
        (removeAttrs derived ["packages" "binaries" "bins" "descriptions"])
        defined
        helpers
      ];
    };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;

    inherit mkToolkit mkAliases mergeDisjoint;

    __tests = let
      inherit (_.debug.assertions) mkTest;
      inherit (_.debug.runners) runTests;
    in
      runTests {
        scriptingIncludesJq = mkTest {
          desired = true;
          outcome = elem "jq" categories.scripting;
          command = "elem \"jq\" categories.scripting";
        };
        desktopShellIsNotScripting = mkTest {
          desired = false;
          outcome = elem "dms-shell" categories.scripting;
          command = "elem \"dms-shell\" categories.scripting";
        };
        desktopCliIsBoth = mkTest {
          desired = [true true];
          outcome = [(elem "dbus" categories.desktop) (elem "dbus" categories.scripting)];
          command = "dbus in desktop and scripting";
        };
        everySourceHasCategory = mkTest {
          desired = [];
          outcome = filter (sourceName: registry.sources.entries.${sourceName}.categories == []) registry.sources.names;
          command = "sources without categories";
        };
        preferDerivedFromSources = mkTest {
          desired = {
            kill = "procps";
            uptime = "procps";
          };
          outcome = defaults.prefer;
          command = "preferFrom sources";
        };
        aliasRendering = mkTest {
          desired = {rmrf = "/bin/rm -rf";};
          outcome = mkAliases {
            lib.escapeShellArgs = concat " ";
            binaries.rm = "/bin/rm";
            aliases.rmrf.cmd = ["rm" "-rf"];
          };
          command = "mkAliases with a stub lib";
        };
      };
  }
