{lix, ...}: {
  # The selected user's Home Manager module owns the router and workers.
  _.resolved.ai.providers.llmhop.defined.enable = false;

  #? Pi's own options live in the user's Home Manager scope, not the host schema.
  #? Startup stays on the free NVIDIA endpoint; the Codex plan/implement router
  #? (`codex/auto`, from the codex-router.ts extension) is one `/model` away.
  home-manager.users.craole = {
    _.resolved.ai.agents.pi.defined = {
      defaults = {
        provider = "nvidia";
        model = "nvidia/nemotron-3-ultra-550b-a55b";
      };
      #? Leave room for Pi's output safety margin and a working answer.
      #? These overrides affect only local models, not the cloud defaults.
      settings = {
        #? Super+A runs plain `pi`; keep discovery and navigation in its defaults.
        defaultTools = ["+codemode" "+tool_search" "+ls" "+grep" "+find"];
        compaction.modelOverrides = {
          "llmhop/unsloth-Qwen3-4B-Instruct-2507-GGUF-Q4-K-M" = {
            reserveTokens = 8192;
            keepRecentTokens = 8192;
          };
          "ollama/qwen3:4b-instruct" = {
            reserveTokens = 8192;
            keepRecentTokens = 8192;
          };
        };
      };
    };
    systemd.user.services.llama-cpp-unsloth-Qwen3-4B-Instruct-2507-GGUF-Q4-K-M.Service = {
      MemoryMax = "10G";
      MemorySwapMax = "0";
    };
  };
  #? One model per stack, bounded to 20 GiB combined and no inference swap.
  #? Q8 KV caches and bounded llama.cpp prefill batches control working memory.
  systemd.services.ollama.serviceConfig = {
    MemoryMax = "10G";
    MemorySwapMax = "0";
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
