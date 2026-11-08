[
  {
    pattern = ["git" "status"];
    decision = "allow";
  }
  {
    pattern = ["git" "diff"];
    decision = "allow";
  }
  {
    pattern = ["git" "log"];
    decision = "allow";
  }
  {
    pattern = ["git" "show"];
    decision = "allow";
  }
  {
    pattern = ["nix" "eval"];
    decision = "allow";
  }
  {
    pattern = ["nix" "flake" "show"];
    decision = "allow";
  }
  {
    pattern = ["git" "push"];
    decision = "allow";
  }
  {
    pattern = ["git" "reset" "--hard"];
    decision = "prompt";
  }
]
