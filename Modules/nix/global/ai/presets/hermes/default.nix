args: {
  "ai-hermes" = import ./base.nix args;
  "ai-hermes-hindsight" = import ./hindsight.nix args;
  "ai-hermes-hindsight-headroom-9router" = import ./hindsight-headroom-nine-router.nix args;
  "ai-hermes-hindsight-headroom-omniroute" = import ./hindsight-headroom-omniroute.nix args;
  "ai-hermes-hindsight-9router" = import ./hindsight-nine-router.nix args;
  "ai-hermes-hindsight-omniroute" = import ./hindsight-omniroute.nix args;
  "ai-hermes-mem0" = import ./mem0.nix args;
}
