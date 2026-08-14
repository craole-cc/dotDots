args: {
  packages =
    (args.pkgsFor {
      sources = {
        hermes-agent = "llm-agents";
      };
    }).packages;
}
