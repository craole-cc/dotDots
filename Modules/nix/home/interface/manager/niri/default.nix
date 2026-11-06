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
  out = config.programs.${mod};

  inherit (context) cfg ctx;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.lists.access) elemAt length;
  inherit (lix.lists.aggregation) foldl';
  inherit (lix.lists.predicates) isIn;
  inherit (lix.lists.transformation) imap0;
  inherit (lix.modules.construction) mkConfig mkContext mkIf;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.schema.io) mkNiriKeybindings;
  inherit (lix.types.predicates) isList;
  niriInterface =
    (lix.schema.ui.mkUI {
      inherit host;
      # TODO: Use recursiveUpdate here
      user = user // {interface = (user.interface or {}) // {desktops = ["niri"];};};
    }).keyboard;

  # TODO: This is SO wrong. I never want to load files like this. This should come from the schema keyboard/actions, not a file stored in the schema
  niriActions = import ../../../../../../Libraries/nix/schema/keyboard/niri.nix {
    _ = lix;
    terminals = apps.terminal or [];
  };

  actionBindings = niriActions.legacy // niriActions.ordered;

  overlayActions = base: projected: fallback: let
    project = binding:
      removeAttrs binding ["key" "mod" "modifier" "category" "description" "application"];
    actionAt = index: let
      kinds = ["exec" "scratchpad" "global"];
    in
      if
        (projected != null)
        && isList projected
        && index < length projected
        && isIn ((elemAt projected index).kind or "exec") kinds
      then elemAt projected index
      else if projected != null && !isList projected && isIn (projected.kind or "exec") kinds
      then projected
      else if isList fallback && index < length fallback
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
    else if !isList base
    then let
      selected = actionAt 0;
    in
      base // optionalAttrs (selected != null) (project selected)
    else base;
  baseBindings = keyboard.bindings or {};
  projectedBindings = niriInterface.bindings or {};

  niriBindings =
    mapAttrs (
      group: bindings:
        if projectedBindings ? ${group} || actionBindings ? ${group}
        then overlayActions bindings (projectedBindings.${group} or null) (actionBindings.${group} or null)
        else bindings
    )
    baseBindings;

  keys =
    keyboard
    // niriInterface
    // {bindings = niriBindings // removeAttrs projectedBindings (attrNames baseBindings);};
  # # TODO:

  niriFloatSticky = inputs."niri-float-sticky".packages.${pkgs.stdenv.hostPlatform.system}.default;

  scratchpads = import ./scratchpads.nix {
    inherit actions apps pkgs lix;
    inherit (out) package;
    keyboard = keys;
  };
  actions = name: arguments: {${name} = arguments;};

  # Editor translucency comes from the same theme schema Hyprland reads, so
  # swapping compositors keeps the declared look instead of losing it.
  editorWindowRules = [
    {
      matches = [{app-id = "^code-insiders$";}];
      opacity = style.opacity.editor.${style.mode};
    }
  ];
in
  mkConfig {
    inherit context;
    options.enable = mkEnable ({inherit context;} // ctx.wantsNiri);
    outputs = mkIf cfg.enable {
      programs.niri = {
        enable = true;
        package = pkgs.niri;
        settings = {
          prefer-no-csd = true;
          binds = foldl' (merged: bindings: merged // bindings) {} [
            (import ./default-bindings.nix {inherit actions lix;})
            (mkNiriKeybindings {
              keyboard = keys;
              inherit actions;
            })
            scratchpads.binds
          ];
          inherit (scratchpads) workspaces;
          window-rules = editorWindowRules ++ scratchpads.window-rules;
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
