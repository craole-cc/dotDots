{settings, ...}: {
  users.users.craole = {
    isNormalUser = true;
    description = "Craig 'Craole' Cole";
    extraGroups = ["networkmanager" "wheel" "storage"];
  };

  #@ Allow sudo commands without password {group: wheel}
  # security.sudo.wheelNeedsPassword = false;

  #@ Allow sudo commands without password {user: craole}
  security.sudo.extraRules = [
    {
      users = ["craole"];
      commands = [
        {
          command = "ALL";
          options = ["SETENV" "NOPASSWD"];
        }
      ];
    }
  ];
}
