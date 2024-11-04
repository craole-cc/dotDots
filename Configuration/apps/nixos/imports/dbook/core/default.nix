{
  imports = [
    ./base
    ./environment
    ./interface
    ./packages
    ./security
    ./services
    ./users
  ];

  config.DOTS = {
    interface.manager = "xfce";
  };
}
