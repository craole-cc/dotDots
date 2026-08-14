args: {
  packages =
    removeAttrs
    ((args.pkgsFor {
      sources = {
        hermes-agent = "llm-agents";
      };
    }).packages)
    ["hermes-desktop"];
}
