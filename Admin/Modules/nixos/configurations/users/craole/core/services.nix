{
  services = {
    atuin.enable = true;
    tailscale.enable = true;
    openvscode-server.enable = true;
    ollama = {
      enable = true;
      loadModels = [
        # "mistral-nemo"
        # "yi-coder:9b"
      ];
    };
  };
}
