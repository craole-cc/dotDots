{lib}: let
  inherit (lib.types) enum port strMatching;
in {
  openclawOptionTypes = {
    #? A non-empty string — useful for required string options.
    nonEmptyStr = strMatching ".+";

    #? A TCP/UDP port number.
    port = port;

    #? A log level enum.
    logLevel = enum [
      "debug"
      "info"
      "warn"
      "error"
    ];

    #? A TLS cipher suite string.
    cipherSuite = strMatching "[A-Z0-9_-]+";

    #? A CIDR network range.
    cidr = strMatching "^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$";
  };
}
