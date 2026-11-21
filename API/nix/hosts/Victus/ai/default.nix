{lix, ...}: {
  # The selected user's Home Manager module owns the router and workers.
  _.resolved.ai.providers.llmhop.defined.enable = false;

  #? Pi's own options live in the user's Home Manager scope, not the host schema.
  #? Startup stays on the free NVIDIA endpoint; the Codex plan/implement router
  #? (`codex/auto`, from the codex-router.ts extension) is one `/model` away.
  home-manager.users.craole._.resolved.ai.agents.pi.defined.defaults = {
    provider = "nvidia";
    model = "nvidia/nemotron-3-ultra-550b-a55b";
  };
  # _.resolved.ai.agents.ollama.defined = {
  #   enable = true;
  #   package = lix.toolkit.packages.ollama-cpu;
  #   host = "127.0.0.1";
  #   sessionVariables = {
  #     OLLAMA_NUM_PARALLEL = "1";
  #     OLLAMA_MAX_LOADED_MODELS = "1";
  #     OLLAMA_CONTEXT_LENGTH = "8192";
  #   };
  # };

  # home-manager.users.craole = import ./hermes;
}
