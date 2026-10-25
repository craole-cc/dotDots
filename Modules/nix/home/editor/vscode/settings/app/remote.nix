{
  context,
  host,
  lix,
  mkEnable,
  user,
  ...
}: let
  inherit (lix.attrsets.construction) listToAttrs optionalAttrs;
  inherit (lix.lists.construction) optional optionals;
  inherit (host.access.remote) ssh tailscale;
  inherit (user.firewall.tcp) ports;

  condition = ssh.enable || tailscale.enable;
  enable = condition;

  name = "remote";
  description = "Remote";
  options.${name}.enable = mkEnable {inherit context condition;};

  extensions = optionals enable (
    [
      "ms-vscode.remote-explorer"
      "GitHub.remotehub"
    ]
    ++ optionals ssh.enable [
      "ms-vscode-remote.remote-ssh"
      "ms-vscode-remote.remote-ssh-edit"
    ]
    ++ optional tailscale.enable "tailscale.vscode-tailscale"
  );

  settings = {
    ${name} =
      {
        #> Automatically forward ports of newly detected running processes.
        #? Disabling this does not prevent all forwarding: extensions and some opened URLs can still forward ports.
        #? See also remote.autoForwardPortsSource.
        autoForwardPorts = true;

        #> Number of auto forwarded ports that triggers the switch from `process` to `hybrid`.
        #? 0 disables the fallback.
        #? Treated as 0 when only remote.autoForwardPortsSource has been configured.
        autoForwardPortsFallback = 20;

        #> Source from which ports are automatically forwarded when remote.autoForwardPorts is true.
        #? When autoForwardPorts is false, this is used to find ports that are already forwarded.
        #? On Windows and macOS remotes, process and hybrid have no effect and output is used.
        #? - process: Forward when discovered by watching for started processes that include a port.
        #? - output: Forward when discovered by reading terminal and debug output. Some ports will be missed, and are not un-forwarded until reload or closed in the Ports view.
        #? - hybrid: Discover via terminal and debug output, but un-forward when the process listening on the port terminates.
        autoForwardPortsSource = "process";

        #> Extensions to install on connecting to a remote when already installed locally.
        defaultExtensionsIfInstalledLocally = [
          "GitHub.copilot"
          "GitHub.copilot-chat"
          "GitHub.vscode-pull-request-github"
        ];

        #> Download extensions locally and install them on the remote.
        downloadExtensionsLocally = false;

        #> Forward local URLs with a port when opened from the terminal and debug console.
        forwardOnOpen = true;

        #> Local host name used for port forwarding.
        localPortHost = "localhost";

        #> Restore the ports you forwarded in a workspace.
        restoreForwardedPorts = true;

        #> Object-valued settings below: keys must stay as-is, do not flatten
        #> Override the kind of an extension.
        #? ui extensions run on the local machine, workspace extensions run on the remote.
        extensionKind = {
          "pub.name" = ["ui"];
        };

        #> Default properties for all ports not covered by remote.portsAttributes.
        #? Example: { onAutoForward = "ignore"; }
        otherPortsAttributes = {};

        #> Properties applied when a specific port is forwarded.
        #? Keys can be a port, a range like "40000-55000", or a process regex like ".+\\/server.js".
        #? Example: "3000" = { label = "Application"; };
        portsAttributes = listToAttrs (
          map (port: {
            name = toString port;
            value = {};
          })
          ports
        );
      }
      // optionalAttrs tailscale.enable {
        tailscale = {
          #> Show files and directories with names that start with a period.
          fileExplorer.showDotFiles = true;

          #> Time in milliseconds between automatic refreshes of the node explorer.
          #? 0 disables automatic refreshing.
          nodeExplorer.refreshInterval = 5000;

          #> Notify when new ports can be served over Tailscale Funnel.
          portDiscovery.enabled = true;

          #> Absolute path to the `tailscaled` unix socket.
          #? null: the extension looks for the default path based on the platform.
          socketPath = null;

          ssh = {
            #> Connection timeout for SSH connections in milliseconds.
            connectionTimeout = 30000;

            #> Default username for SSH connections.
            defaultUsername = null;
          };
        };
      };
  };
in {inherit name description enable options extensions settings;}
