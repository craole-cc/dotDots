{ ... }: {
  services.btrfs = {
    autoScrub = {
      enable = true;
      fileSystems = [ "/" ]; #TODO# Is this to specific
    };
  };
}
