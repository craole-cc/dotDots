{
  #~@ POSIX-compatible
  bash = {
    posix = true;
    interactive = true;
    system = true;
    language = "c";
  };
  dash = {
    posix = true;
    interactive = false;
    system = true;
    language = "c";
  };
  sh = {
    posix = true;
    interactive = false;
    system = true;
    language = "c";
  };
  ksh = {
    posix = true;
    interactive = true;
    system = true;
    language = "c";
  };
  zsh = {
    posix = true;
    interactive = true;
    system = true;
    language = "c";
  };

  #~@ Modern
  fish = {
    posix = false;
    interactive = true;
    system = false;
    language = "c";
  };
  nushell = {
    posix = false;
    interactive = true;
    system = false;
    language = "rust";
  };
  elvish = {
    posix = false;
    interactive = true;
    system = false;
    language = "go";
  };
  pwsh = {
    posix = false;
    interactive = true;
    system = false;
    language = "csharp";
  };

  #~@ Legacy/niche
  tcsh = {
    posix = false;
    interactive = true;
    system = false;
    language = "c";
  };
}
