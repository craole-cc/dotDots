let
  extensions = [
    "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
    "jjmflmamggggndanpgfnpelongoepncg" # Extensity
    "gcbommkclmclpchllfjekcdonpmejbdp" # HTTPS Everywhere
    "mbniclmhobmnbdlbpiphghaielnnpgdp" # Lightshot
    # "chlffgpmiacpedhhbkiomidkjlcfhogd" # PushBullet
    "hipekcciheckooncpjeljhnekcoolahp" # Tabliss
    "iaiomicjabeggjcfkbimgmglanimpnae" # Tab Session Manager
    "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
  ];
  url = "https://clients2.google.com/service/update2/crx";
  policies = {
    ExtensionInstallForcelist = map (id: "${id};${url}") extensions;
  };
in
{
  inherit extensions policies;
}
