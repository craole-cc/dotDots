{
  config,
  host,
  keyboard,
  lib,
  lix,
  pkgs,
  style,
  apps,
  user,
  inputs,
  ...
}: let
  context = mkContext {
    inherit config host;
    dom = "interface";
    sub = "managers";
    mod = "niri";
  };
  inherit (context) cfg ctx;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.schema.io) mkNiriKeybindings;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.lists.access) elemAt length;
  inherit (lix.types.predicates) isList;
  inherit (lix.lists.transformation) imap0;
  inherit (lib.modules) mkIf;
  niriInterface =
    (lix.schema.ui.mkUI {
      inherit host;
      user =
        user
        // {
          interface = (user.interface or {}) // {desktops = ["niri"];};
        };
    }).keyboard;
  niriActions = import ../../../../../../Libraries/nix/schema/keyboard/niri.nix {
    _ = lix;
    terminals = apps.terminal or [];
  };
  actionBindings = niriActions.legacy // niriActions.ordered;
  overlayActions = base: projected: fallback: let
    project = binding:
      removeAttrs binding ["key" "mod" "modifier" "category" "description" "application"];
    actionAt = index:
      if
        projected
        != null
        && isList projected
        && index < length projected
        && lib.lists.elem ((elemAt projected index).kind or "exec") ["exec" "scratchpad" "global"]
      then elemAt projected index
      else if projected != null && !isList projected && lib.lists.elem (projected.kind or "exec") ["exec" "scratchpad" "global"]
      then projected
      else if isList fallback && index < length fallback
      then elemAt fallback index
      else fallback;
  in
    if isList base
    then
      imap0 (
        index: binding:
          binding
          // (let
            selected = actionAt index;
          in
            if selected == null
            then {}
            else project selected)
      )
      base
    else if !isList base
    then let
      selected = actionAt 0;
    in
      base
      // (
        if selected == null
        then {}
        else project selected
      )
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
  niriKeyboard =
    keyboard
    // niriInterface
    // {
      bindings = niriBindings // removeAttrs projectedBindings (attrNames baseBindings);
    };
  niriPackage = config.programs.niri.package;
  niriFloatSticky = inputs."niri-float-sticky".packages.${pkgs.stdenv.hostPlatform.system}.default;
  scratchpads = import ./scratchpads.nix {
    inherit actions;
    inherit apps;
    keyboard = niriKeyboard;
    inherit lib niriPackage pkgs;
  };
  actions = config.lib.niri.actions;
  defaultBinds = import ./default-bindings.nix {inherit actions lix;};

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
          binds =
            defaultBinds
            // (mkNiriKeybindings {
              keyboard = niriKeyboard;
              inherit actions;
            })
            // scratchpads.binds;
          inherit (scratchpads) workspaces;
          window-rules = editorWindowRules ++ scratchpads.window-rules;
        };
      };
      home.packages = scratchpads.packages ++ [niriFloatSticky];
      systemd.user.services.niri-float-sticky = {
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
  }
