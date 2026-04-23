{
  pkgs,
  inputs,
  ...
}:
pkgs.testers.runNixOSTest {
  name = "openclaw-unit";

  nodes.machine = {
    ...
  }: {
    imports = [inputs.self.nixosModules.openclaw];

    services.openclaw = {
      enable = true;
      port = 8080;
      host = "127.0.0.1";
      logLevel = "debug";
    };

    #> Allow the VM to reach the loopback health endpoint.
    networking.firewall.enable = false;
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("openclaw.service")

    # Assert the unit is active (running), not failed.
    machine.succeed("systemctl is-active openclaw.service")

    # Assert the health endpoint returns HTTP 200.
    machine.succeed(
      "${pkgs.curl}/bin/curl --fail --silent --max-time 10 http://127.0.0.1:8080/health"
    )

    # Assert the service runs as a non-root DynamicUser.
    pid = machine.succeed(
      "systemctl show -p MainPID --value openclaw.service"
    ).strip()
    uid = machine.succeed(f"awk '/^Uid:/ {{print $2}}' /proc/{pid}/status").strip()
    assert uid != "0", f"openclaw must not run as root, got UID={uid}"

    # Assert all capabilities have been dropped (CapPrm == 0).
    cap_prm = machine.succeed(
      f"grep CapPrm /proc/{pid}/status | awk '{{print $2}}'"
    ).strip()
    assert cap_prm == "0000000000000000", (
      f"Expected CapPrm=0000000000000000, got {cap_prm}"
    )

    machine.shutdown()
  '';
}
