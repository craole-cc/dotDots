# Victus AI Services

Victus supports cloud inference and one explicit local model through the
Home Manager llmhop router at `http://127.0.0.1:11435/v1`.
Automatic model defaults remain disabled. The single CPU llama.cpp worker
uses `unsloth/Qwen3-4B-Instruct-2507-GGUF:Q4_K_M`, an 8192-token context,
one parallel slot, and Jinja tool templates. It downloads weights on first start.
The system llmhop module is disabled to avoid a second router on the same port.

Hermes declares the ChatGPT Codex endpoint explicitly for its OpenAI models.
The main configuration uses `gpt-6.1-sol`; the receptionist uses
`gpt-6-luna`. Each profile keeps its own writable OAuth credentials and
conversation history.

Pi receives its local model catalog from the resolved llmhop configuration in
`~/.pi/agent/models.json`. Choose the llmhop model with `/model`; cloud providers
remain available through their usual credentials, including `OPENROUTER_API_KEY`
loaded from `~/Private/pi.env`. No cloud request is needed to use the local model.

The local 9Router, Headroom and Hindsight tools have separate configuration;
removing local model servers does not remove those tools.

Apply with `nhs`, then restart Pi. Check `systemctl --user status llmhop` and
`curl http://127.0.0.1:11435/v1/models` after the initial model download.
Local tool use and performance require a live check after activation.
