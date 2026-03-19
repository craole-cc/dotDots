{_, ...}: {
  __doc = ''
    Module Evaluation and System Generation

    Provides the orchestration layer for turning discovered hosts, resolved
    flake inputs, generated package sets, and assembled module lists into
    fully evaluated system configurations.

    This file is responsible for two major tasks:

    1. Evaluating host systems via `evalModules`.
    2. Generating per-system flake-style output matrices from a function.
  '';
  inherit (_.modules.core) mkCore;
  inherit (_.modules.home) mkHome;
}
