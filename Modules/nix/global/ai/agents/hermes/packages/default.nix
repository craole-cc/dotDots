{pkgsFor, ...}: {
  packages =
    removeAttrs
    ((pkgsFor {
      sources = {
        hermes-agent = "llm-agents";
      };
    }).packages)
    ["hermes-desktop"];
}
