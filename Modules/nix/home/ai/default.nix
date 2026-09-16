{
  args,
  core,
  lix,
  inputs, # This is not ideal
  ...
}: {
  imports = [./hermes.nix];
  # inherit devShells;
  # inherit (default) env packages shellHook;
  # description = "AI Development";
}
