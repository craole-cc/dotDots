{
  commands = [
    {
      help = "Update the system configuration";
      name = "floor";
      command = ". bin/init_dots_bin && dots --core";
      category = "[general commands]";
    }
    {
      help = "Update the user configuration";
      name = "flare";
      command = ". bin/init_dots_bin && dots --home";
      category = "[general commands]";
    }
    {
      help = "Update the sources and repository";
      name = "flake";
      command = ". bin/init_dots_bin && dots --update && geet";
      category = "[general commands]";
    }
    {
      help = "Open the flake in the editor";
      name = "edit";
      command = "ede .";
      category = "flake commands";
    }
    {
      help = "Format all files in the flake including scripts";
      name = "lish";
      command = "dots --lint";
      category = "flake commands";
    }
    {
      help = "Format all files in the flake";
      name = "lint";
      command = "treefmt --fail-on-change";
      category = "flake commands";
    }
    {
      help = "Update the sources";
      name = "lock";
      command = ". bin/init_dots_bin && dots --update";
      category = "flake commands";
    }
    {
      help = "Update the repository";
      name = "push";
      command = ". bin/init_dots_bin && geet";
      category = "flake commands";
    }
    {
      help = "Show the flake information";
      name = "show";
      command = "nix flake show --all-systems";
      category = "flake commands";
    }
    # {
    #   help = "Show the flake information";
    #   name = "pkgs";
    #   command = ''. bin/init_dots_bin && dots --pkgs $1'';
    #   category = "flake commands";
    # }
    {
      help = "Check the flake for potential errors";
      name = "chck";
      command = "nix flake check --all-systems --show-trace --impure";
      category = "flake commands";
    }
    {
      help = "Remove old generations and temporary files";
      name = "clean";
      command = ". bin/init_dots_bin && dots --clean";
      category = "system commands";
    }
    {
      help = "Rebuild the NixOS configuration";
      name = "rebuild";
      command = ". bin/init_dots_bin && dots --core";
      category = "system commands";
    }
    # {
    #   help = "Rebuild the Home-Manager configuration";
    #   name = "mkHome";
    #   command = ''. bin/init_dots_bin && dots --home'';
    #   category = "system commands";
    # }
    {
      help = "Close the terminal";
      name = "quit";
      command = ''kill -KILL "$(ps -o ppid= -p $$)"'';
      category = "system commands";
    }
    {
      help = "Logout";
      name = "reload";
      command = "leave --logout";
      category = "system commands";
    }
    {
      help = "Reboot";
      name = "restart";
      command = "leave --reboot";
      category = "system commands";
    }
    {
      help = "Shutdown";
      name = "retire";
      command = "leave --shutdown";
      category = "system commands";
    }
  ];

  env = [
    # {
    #   name = "DIRENV_LOG_FORMAT";
    #   value = "";
    # }
  ];
}
