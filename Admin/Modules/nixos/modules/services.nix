{alpha, ...}: {
  services = {
    displayManager = {
      autoLogin = {
        enable = true;
        user = alpha;
      };
    };
  };
}
