#PATH: config.nix
{
  users = {
    craole = {
      username = "craole";
      fullname = "Craig 'Craole' Cole";
      email = "info@craole.cc";
      sshKey = "";
    };
  };

  hosts = {
    QBX.paths.local = /home/craole/.dots;
    dbook.paths.local = /home/craole/Documents/dotfiles;
  };
}
