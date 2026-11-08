{
  lix,
  pkgs,
  inputs ? {},
  ...
}: {
  skills = import ./skills {inherit lix pkgs inputs;};
  rules = import ./rules;
}
