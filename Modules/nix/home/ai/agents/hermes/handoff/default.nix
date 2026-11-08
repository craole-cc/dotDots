{
  cfg,
  lix,
  resolve,
  ...
}: let
  inherit (lix.modules.construction) mkLayer;
  inherit (lix.options.construction) mkFalse mkOption;
  inherit (lix.types.primitives) int;
  inherit (lix.strings.construction) toJSON;
  inherit (lix.attrsets.transformation) filterAttrs;
  resolved = resolve {};
  routes = {
    default = ["coordinator"];
    coordinator = ["developer" "librarian" "anthropologist" "assistant" "architect" "auditor" "scribe" "intern"];
    developer = ["scribe" "intern"];
    librarian = ["scribe" "intern"];
    anthropologist = ["scribe" "intern"];
    assistant = ["scribe" "intern"];
    architect = [];
    auditor = [];
    scribe = [];
    intern = [];
  };
  active = name: name == "default" || (cfg.profiles.${name}.enable or false);
in {
  options.handoff.enable = mkFalse "Enable restricted named-bot handoffs from Telegram Hermes through Coordinator.";
  options.handoff.limits.hops = mkOption {
    type = int;
    default = 16;
    description = "Maximum bot-to-bot chain hops, including nested commissions and correction exchanges.";
  };
  resolutions = {
    handoff = mkLayer 1000 (resolved.handoff or {});
    settings.gateway.bot_loop_guard = lix.modules.construction.mkIf cfg.handoff.enable (mkLayer 90 {
      enabled = true;
      max_hops = cfg.handoff.limits.hops;
      bot_replies_expect_reply = false;
    });
    home.file."team-handoff.json" = toJSON {
      version = 1;
      enabled = cfg.handoff.enable;
      gateway_platforms = ["telegram"];
      routes = filterAttrs (name: _targets: active name) (lix.attrsets.transformation.mapAttrs
        (_name: targets: lix.lists.transformation.filter active targets)
        routes);
    };
  };
  outputs.assertions = [
    {
      assertion = cfg.handoff.limits.hops > 0;
      message = "Named team handoff hop limit must be a positive integer.";
    }
    {
      assertion = !cfg.handoff.enable || (cfg.gateway.enable && cfg.gateway.multiplex && (cfg.profiles.coordinator.enable or false));
      message = "Named team handoff requires the multiplexed gateway and an enabled Coordinator.";
    }
  ];
}
