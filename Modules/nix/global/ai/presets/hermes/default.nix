args: {
  "ai-hermes" = import ./base.nix args;
  "ai-hermes-hindsight" = import ./hindsight.nix args;
  "ai-hermes-hindsight-omniroute" = import ./hindsight-omniroute.nix args;
  "ai-hermes-mem0" = import ./mem0.nix args;
}
