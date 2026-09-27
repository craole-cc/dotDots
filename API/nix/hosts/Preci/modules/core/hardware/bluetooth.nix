{lix, ...}: {
  hardware = {
    bluetooth = {
      enable = lix.infrastructure.functionalities.bluetooth;
      powerOnBoot = true;
    };
  };
}
