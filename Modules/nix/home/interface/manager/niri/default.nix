{
  config,
  host,
  keyboard,
  lix,
  pkgs,
  style,
  apps,
  user,
  inputs,
  ...
}: let
  dom = "interface";
  sub = "managers";
  mod = "niri";
  context = mkContext {inherit config host dom sub mod;};

  #> The home-manager module declares `wayland.windowManager.niri`, not
  #> `programs.niri` (that one is NixOS-only).
  package = pkgs.niri;

  inherit (context) cfg ctx;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.transformation) mapAttrs removeAttrs;
  inherit (lix.lists.access) elemAt length;
  inherit (lix.lists.aggregation) foldl';
  inherit (lix.lists.predicates) isIn;
  inherit (lix.lists.transformation) imap0;
  inherit (lix.modules.construction) mkConfig mkContext mkIf;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.schema.io) mkNiriKeybindings;
  inherit (lix.schema.ui) mkUI;
  inherit (lix.types.predicates) isAttrs isList;

  niriInterface =
    (mkUI {
      inherit host;
      user = recursiveUpdate user {interface.desktops = ["niri"];};
    }).keyboard;

  # TODO: This is SO wrong. I never want to load files like this. This should come from the schema keyboard/actions, not a file stored in the schema
  niriActions = import ../../../../../../Libraries/nix/schema/keyboard/niri.nix {
    _ = lix;
    terminals = apps.terminal or [];
  };

  actionBindings = niriActions.legacy // niriActions.ordered;

  overlayActions = base: projected: fallback: let
    project = binding:
      removeAttrs binding
      ["key" "mod" "modifier" "category" "description" "application"];
    kinds = ["exec" "scratchpad" "global"];
    actionAt = index:
      if
        (projected != null)
        && isList projected
        && index < length projected
        && isIn ((elemAt projected index).kind or "exec") kinds
      then elemAt projected index
      else if
        (projected != null)
        && !isList projected
        && isIn (projected.kind or "exec") kinds
      then projected
      else if isList fallback && (index < length fallback)
      then elemAt fallback index
      else fallback;
  in
    if isList base
    then
      imap0 (
        index: binding: let
          selected = actionAt index;
        in
          binding // optionalAttrs (selected != null) (project selected)
      )
      base
    else let
      selected = actionAt 0;
    in
      base // optionalAttrs (selected != null) (project selected);

  baseBindings = keyboard.bindings or {};
  projectedBindings = niriInterface.bindings or {};

  niriBindings =
    mapAttrs (
      group: bindings:
        if projectedBindings ? ${group} || actionBindings ? ${group}
        then
          overlayActions bindings
          (projectedBindings.${group} or null)
          (actionBindings.${group} or null)
        else bindings
    )
    baseBindings;

  keys =
    keyboard
    // niriInterface
    // {
      bindings =
        niriBindings
        // removeAttrs projectedBindings
        (attrNames baseBindings);
    };

  niriFloatSticky = inputs."niri-float-sticky".packages.${pkgs.stdenv.hostPlatform.system}.default;

  scratchpads = import ./scratchpads.nix {
    inherit actions apps pkgs lix package;
    keyboard = keys;
  };
  actions = name: arguments: {${name} = arguments;};

  #? niri expects exactly one action as a bind's child node and every
  #? bind-level option as a property on the bind node itself. hotkey-overlay
  #? titles are a property too (hotkey-overlay-title), not a child node.
  bindToKdl = bind: let
    action = bind.action or {};
    title = bind."hotkey-overlay".title or null;
    props =
      optionalAttrs (title != null) {"hotkey-overlay-title" = title;}
      // optionalAttrs (bind ? repeat) {inherit (bind) repeat;}
      // optionalAttrs (bind ? allow-when-locked) {allow-inhibiting = bind.allow-when-locked;};
  in
    {_children = [action];}
    // optionalAttrs (props != {}) {_props = props;};

  # Editor translucency comes from the same theme schema Hyprland reads, so
  # swapping compositors keeps the declared look instead of losing it.
  editorWindowRules = [
    {
      match._props.app-id = "^code-insiders$";
      opacity = style.opacity.editor.${style.mode};
    }
  ];
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable ({inherit context;} // ctx.wantsNiri);
    };
    outputs = mkIf cfg.enable {
      wayland.windowManager.niri = {
        enable = true;
        inherit package;
        settings = {
          prefer-no-csd = true;
          binds = mapAttrs (_: bindToKdl) (foldl' (merged: bindings: merged // bindings) {} [
            (import ./default-bindings.nix {inherit actions lix;})
            (mkNiriKeybindings {
              keyboard = keys;
              inherit actions;
            })
            scratchpads.binds
          ]);
          #? niri >= 26 declares each startup workspace as its own node.
          workspace = map (name: {_args = [name];}) (attrNames scratchpads.workspaces);
          window-rule = editorWindowRules ++ scratchpads.window-rules;
        };
      };

      home = {
        packages = scratchpads.packages ++ [niriFloatSticky];
      };

      systemd = {
        user.services.niri-float-sticky = {
          Unit = {
            Description = "Niri floating-window pinning helper";
            After = ["graphical-session.target"];
            PartOf = ["graphical-session.target"];
          };
          Service = {
            ExecStart = "${niriFloatSticky}/bin/niri-float-sticky --disable-auto-stick --allow-moving-to-foreign-monitors";
            Restart = "on-failure";
            RestartSec = 2;
          };
          Install.WantedBy = ["graphical-session.target"];
        };
      };
    };
  }
