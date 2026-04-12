{
  _,
  __moduleDir,
  __moduleName,
  ...
}: let
  inherit (_.applications.primitives) toValue toName;
  inherit (_.applications.queries) mkEq mkMember;
  inherit (_.applications.selection) withFlag;
  inherit (_.attrsets.access) attrValues;
  inherit (_.attrsets.construction) genAttrs listToAttrs;
  inherit (_.attrsets.transformation) filterAttrs;
  inherit (_.lists.predicates) isIn;
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;
  default = _.applications.filters.groups;

  /**
      Partition an application set by the distinct values of the `maturity` field.

      Entries where `maturity` is absent or `null` are excluded.

      # Type
  ```nix
      mkMaturity :: { set :: AttrSet } -> { ${maturity} :: AttrSet }
  ```

      # Examples
  ```nix
      mkMaturity { set = { a = { maturity = "stable"; }; b = { maturity = "beta"; }; }; }
      # => { stable = { a = { maturity = "stable"; }; };
      #      beta   = { b = { maturity = "beta";   }; }; }

      # Entries without maturity are excluded
      mkMaturity { set = { a = { maturity = "stable"; }; b = {}; }; }
      # => { stable = { a = { maturity = "stable"; }; }; }
  ```
  */
  mkMaturity = {set}:
    mkEq {
      inherit set;
      field = "maturity";
    };

  /**
      Index an application set by members of the `protocol` list field.

      An entry appears under every protocol value it lists. Entries where
      `protocol` is absent or empty are excluded from all keys.

      # Type
  ```nix
      mkProtocol :: { set :: AttrSet } -> { ${protocol} :: AttrSet }
  ```

      # Examples
  ```nix
      mkProtocol {
        set = {
          a = { protocol = [ "wayland" "x11" ]; };
          b = { protocol = [ "wayland" ]; };
        };
      }
      # => { wayland = { a = ...; b = ...; };
      #      x11     = { a = ...; }; }
  ```
  */
  mkProtocol = {set}:
    mkMember {
      inherit set;
      field = "protocol";
    };

  /**
      Partition an application set by the distinct values of the `scope` field.

      Entries where `scope` is absent or `null` are excluded.

      # Type
  ```nix
      mkScope :: { set :: AttrSet } -> { ${scope} :: AttrSet }
  ```

      # Examples
  ```nix
      mkScope {
        set = { a = { scope = "user"; }; b = { scope = "system"; }; };
      }
      # => { user   = { a = { scope = "user";   }; };
      #      system = { b = { scope = "system"; }; }; }
  ```
  */
  mkScope = {set}:
    mkEq {
      inherit set;
      field = "scope";
    };

  /**
      Build a capability map for an application set across a fixed set of
      boolean capability fields: `acceleration`, `compositing`, `remote`,
      and `floating`.

      Each key in the result contains the subset of entries that have that
      capability flag set to true. Empty subsets are omitted.

      # Type
  ```nix
      mkCapability :: { set :: AttrSet } -> { ${capability} :: AttrSet }
  ```

      # Examples
  ```nix
      mkCapability {
        set = {
          a = { acceleration = true; compositing = false; };
          b = { acceleration = true; compositing = true;  };
        };
      }
      # => { acceleration = { a = ...; b = ...; };
      #      compositing  = { b = ...; }; }

      # Capabilities with no matching entries are omitted entirely
      mkCapability { set = { a = { floating = false; }; }; }
      # => {}
  ```
  */
  mkCapability = {set}: let
    fields = [
      "acceleration"
      "compositing"
      "floating"
      "fuzzy"
      "history"
      "nagigation"
      "remote"
      "stacking"
      "tiling"
    ];
  in
    filterAttrs (_: v: v != {}) (
      genAttrs fields (field: withFlag {inherit field set;})
    );

  /**
      Partition an application set by the value of `config.file`, scoping
      only to entries that have a non-null `config` field.

      Entries without `config` or with a null `config.file` are excluded.

      # Type
  ```nix
      mkConfigFile :: { set :: AttrSet } -> { ${configFile} :: AttrSet }
  ```

      # Examples
  ```nix
      mkConfigFile {
        set = {
          a = { config = { file = ".bashrc"; home = "/home/user"; }; };
          b = { config = { file = ".zshrc";  home = "/home/user"; }; };
          c = {};
        };
      }
      # => { ".bashrc" = { a = ...; };
      #      ".zshrc"  = { b = ...; }; }
  ```
  */
  mkConfigFile = {set}: let
    getFile = toValue {field = "config.file";};
    withCfg = filterAttrs (_: a: toValue {field = "config";} a != null) set;
    keys = unique (filter (v: v != null) (map getFile (attrValues withCfg)));
  in
    genAttrs keys (file: filterAttrs (_: a: getFile a == file) set);

  /**
      Build a combined grouping attrset from an application set, keyed by
      `toName`-derived attribute names. Supports semantic fields (maturity,
      protocol, scope, capability, config) out of the box; additional fields
      fall back to `mkEq` or `mkMember` based on which list they appear in.

      # Type
  ```nix
      mkStandard :: {
        set    :: AttrSet,
        eq     :: [string],   # optional, default []
        member :: [string],   # optional, default []
        fields :: [string],   # optional, default []
      } -> AttrSet
  ```

      # Examples
  ```nix
      mkStandard {
        set    = { ... };
        eq     = ["compositor" "scope"];
        member = ["layouts" "greeters"];
        fields = ["protocol" "maturity"];
      }
      # => { byCompositor = ...; byScope = ...; byLayouts = ...;
      #      byGreeters = ...; byProtocol = ...; byMaturity = ...; }

      # Semantic fields use their dedicated group builder regardless of eq/member
      mkStandard { set = { ... }; fields = ["capability"]; }
      # => { byCapability = { acceleration = ...; compositing = ...; }; }
  ```
  */
  mkStandard = {
    set,
    eq ? [],
    member ? [],
    fields ? [],
  }: let
    #~@ well-known fields with dedicated builders
    perField = {
      maturity = mkMaturity {inherit set;};
      protocol = mkProtocol {inherit set;};
      config = mkConfigFile {inherit set;};
      capability = mkCapability {inherit set;};
      scope = mkScope {inherit set;};
    };
    allFields = unique (eq ++ member ++ fields);
  in
    listToAttrs (map (field: {
        name = toName {
          inherit field;
          prefix = "by";
        };
        value =
          perField.${
            field
          } or (
            #? fall back to eq or member query for unknown fields
            if isIn field eq
            then mkEq {inherit set field;}
            else mkMember {inherit set field;}
          );
      })
      allFields);
in
  _.meta.mkModuleExports {
    directory = __moduleDir;
    filename = __moduleName;
    doc = ''
      Application group builders (Layer 3).

      Provides semantic grouping functions that partition an application set
      by well-known fields (maturity, protocol, scope, capability, config),
      and a composable standard grouping builder used by section constructors.

      Depends on: applications {queries, primitives, selectors}.
    '';

    functions =
      default
      // {
        inherit
          mkCapability
          mkConfigFile
          mkMaturity
          mkProtocol
          mkScope
          mkStandard
          ;
      };
  }
