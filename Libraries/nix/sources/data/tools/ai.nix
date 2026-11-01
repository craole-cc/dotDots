{mkSource, ...}: {
  ollama = mkSource {
    categories = ["scripting" "ai"];
    description = "Local language model inference";
  };

  ollama-cpu = mkSource {
    categories = ["scripting" "ai"];
    description = "Local language model inference on the CPU";
  };

  llmhop = mkSource {
    categories = ["scripting" "ai"];
    description = "Language model request router";
    input = "llmhop";
  };
}
