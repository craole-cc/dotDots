{...}: {
  bash = {
    categories = ["shell"];
    posix = true;
    interactive = true;
    system = true;
    language = "c";
  };
  dash = {
    categories = ["shell"];
    posix = true;
    interactive = false;
    system = true;
    language = "c";
  };
  sh = {
    categories = ["shell"];
    posix = true;
    interactive = false;
    system = true;
    language = "c";
  };
  ksh = {
    categories = ["shell"];
    posix = true;
    interactive = true;
    system = true;
    language = "c";
  };
  zsh = {
    categories = ["shell"];
    posix = true;
    interactive = true;
    system = true;
    language = "c";
  };
  fish = {
    categories = ["shell"];
    posix = false;
    interactive = true;
    system = false;
    language = "c";
  };
  nushell = {
    categories = ["shell"];
    posix = false;
    interactive = true;
    system = false;
    language = "rust";
  };
  elvish = {
    categories = ["shell"];
    posix = false;
    interactive = true;
    system = false;
    language = "go";
  };
  pwsh = {
    categories = ["shell"];
    posix = false;
    interactive = true;
    system = false;
    language = "csharp";
  };
  tcsh = {
    categories = ["shell"];
    posix = false;
    interactive = true;
    system = false;
    language = "c";
  };
}
