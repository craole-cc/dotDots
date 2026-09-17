{
  #   config,
  #   host,
  #   lix,
  #   ...
  # }: let
  #   dom = "ai";
  #   sub = "agents";
  #   mod = "hermes";
  #   inherit (lix.modules.construction) mkConfig mkContext;
  #   inherit (lix.lists.predicates) isIn;
  #   inherit (lix.options.construction) mkEnable;
  #   context = mkContext {
  #     inherit config dom sub mod;
  #   };
  #   ai = (host.users.data.primary or {}).applications.ai or {};
  #   selectedApplications = [
  #     (ai.primary or null)
  #     (ai.secondary or null)
  #     (ai.tertiary or null)
  #   ];
  #   isSelected =
  #     isIn [
  #       "hermes"
  #       "hermes-agent"
  #       "hermes-desktop"
  #     ]
  #     selectedApplications;
  # in
  #   mkConfig {
  #     inherit context;
  #     options.enable = mkEnable {
  #       inherit context;
  #       condition = isSelected;
  #     };
  #     outputs = {
  #       services.hermes-agent = {
  #         enable = true;
  #         # The system module runs the gateway. Install its optional messaging
  #         # integrations without imposing a model, secret source, or backend on
  #         # every host; those remain explicit host-level service settings.
  #         extraDependencyGroups = ["messaging"];
  #       };
  #     };
}
