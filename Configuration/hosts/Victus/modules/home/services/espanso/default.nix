{policies, ...}:
with policies; {
  services.espanso.enable = dev || productivity || web;
  imports = [./shared];
}
