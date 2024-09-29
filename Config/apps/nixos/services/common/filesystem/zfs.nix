{ ... }: {
  services.zfs = {
    autoScrub = {
      enable = true;
    };
    trim.enable = true;
  };
}
