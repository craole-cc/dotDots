let
  QBX = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGvtPxp3y1OqmKA62pwevC4JWoJsK3pLiGZJG22SNlXG root@qbx";

  all = [QBX];
in {
  "vpn-auth.age".publicKeys = all;
}
