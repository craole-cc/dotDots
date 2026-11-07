# Victus AI Services

Victus uses cloud inference. Its package selections omit Ollama and llmhop,
and hardware-derived local models are disabled. The shared user defaults
still make local inference available on other hosts.

Hermes declares the ChatGPT Codex endpoint explicitly for its OpenAI models.
The main configuration uses `gpt-6.1-sol`; the receptionist uses
`gpt-6-luna`. Each profile keeps its own writable OAuth credentials and
conversation history.

After activation, Ollama, llmhop and llama.cpp model workers should be absent
from the system service configuration. Changing the declaration does not
remove previously downloaded model weights or old Nix generations. Remove
known model downloads separately; do not clear unrelated caches or application
state as part of service activation.

The local 9Router, Headroom and Hindsight tools have separate configuration;
removing local model servers does not remove those tools.

After resolving any remaining evaluation errors, apply the configuration with
`nhs`, then restart Hermes. No computer reboot is required for these changes.
