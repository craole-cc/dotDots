{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.zfs-root.per-user.craole.templates.server;
  inherit (lib) mkDefault mkOption types mkIf;
in {
  options.zfs-root.per-user.craole.templates.server = {
    enable = mkOption {
      description = "Enable server config template by craole";
      type = types.bool;
      default = false;
    };
  };
  config = mkIf cfg.enable {
    environment.etc = {
      "ssh/ssh_host_ed25519_key" = {
        source = "/oldroot/etc/ssh/ssh_host_ed25519_key";
        mode = "0600";
      };
      "ssh/ssh_host_rsa_key" = {
        source = "/oldroot/etc/ssh/ssh_host_rsa_key";
        mode = "0600";
      };
    };
    zfs-root.fileSystems.datasets = {
      "rpool/nixos/home" = "/oldroot/home";
      "rpool/data/file" = "/home";
    };
    fileSystems = {
      "/tmp/BitTorrent" = {
        device = "rpool/data/bt";
        fsType = "zfs";
        options = ["noatime" "X-mount.mkdir=755"];
      };
    };

    services.zfs = {
      autoScrub = {
        enable = true;
        interval = "quarterly";
      };
      autoSnapshot = {
        enable = true;
        flags = "-k -p --utc";
        monthly = 48;
      };
    };
    services.nfs = {
      server = {
        enable = true;
        createMountPoints = true;
        exports = ''
          /tmp/BitTorrent    192.168.1.0/24(ro,all_squash)
        '';
        # disable nfs3
        extraNfsdConfig = ''
          vers2=n
          vers3=n
        '';
      };
    };
    services.samba = {
      enable = true;
      openFirewall = true;
      extraConfig = ''
        guest account = nobody
        map to guest = bad user
        server smb encrypt = off
      '';
      shares = {
        bt = {
          path = "/tmp/BitTorrent";
          "read only" = true;
          browseable = "yes";
          "guest ok" = "yes";
          "hosts allow" = "192.168.1.";
        };
      };
    };
    networking.firewall = {
      allowedTCPPorts = [
        # bt
        51413
        # nfsv4
        2049
        # 让妈妈用ygg看电影
        62912
      ];
      allowedUDPPorts = [
        # bt
        51413
      ];
    };
    boot.kernel.sysctl = {
      "net.core.rmem_max" = 4194304;
      "net.core.wmem_max" = 1048576;
      "fs.file-max" = 65536;
    };
    systemd.services.rtorrent.serviceConfig.LimitNOFILE = 10240;
    systemd.tmpfiles.rules = [
      "d '/tmp/BitTorrent' 0755 rtorrent rtorrent -"
      "d '/tmp/rtorrent_自动添加' 0770 rtorrent users -"
    ];
    services.rtorrent = {
      enable = true;
      dataDir = "/tmp/BitTorrent";
      downloadDir = "/tmp/BitTorrent/已下载";
      openFirewall = false;
      # https://rtorrent-docs.readthedocs.io/en/latest/cmd-ref.html
      # fix directory permission and remove execute.nothrow after 23.05
      # https://github.com/NixOS/nixpkgs/pull/212153
      configText = ''
        # set rpc socket permission
        # enabled lighttpd access
        schedule = scgi_permission,0,0,"execute.nothrow=\"${pkgs.acl}/bin/setfacl\",\"-mu:lighttpd:rwx,u:craole:rwx\",(cfg.rpcsock)"

        # rtorrent program settings
        encoding.add = UTF-8
        pieces.hash.on_completion.set = 0
        system.umask.set = 0022

        # torrent network settings
        network.port_range.set = 51413-51413
        dht.mode.set = on
        protocol.pex.set = yes
        trackers.use_udp.set = yes
        protocol.encryption.set = none

        # watch dir
        # created and permission set by systemd tmpdir rules
        method.insert = cfg.watchDir1, private|const|string, "/tmp/rtorrent_自动添加"
        # Watch directories (add more as you like, but use unique schedule names)
        schedule2 = watch_start, 10, 10, ((load.start, (cat, (cfg.watchDir1), "/*.torrent")))

        # disable prealloc for zfs
        system.file.allocate.set = 0

        # performance tuning
        # https://github.com/rakshasa/rtorrent/issues/1046
        ### BitTorrent
        # Global upload and download rate in KiB, `0` for unlimited
        throttle.global_down.max_rate.set = 0
        throttle.global_up.max_rate.set = 0

        # Maximum number of simultaneous downloads and uploads slots
        throttle.max_downloads.global.set = 150
        throttle.max_uploads.global.set = 300

        # Maximum and minimum number of peers to connect to per torrent while downloading
        throttle.min_peers.normal.set = 30
        throttle.max_peers.normal.set = 150

        # Same as above but for seeding completed torrents (seeds per torrent)
        throttle.min_peers.seed.set = -1
        throttle.max_peers.seed.set = -1

        network.max_open_files.set = 4096
        network.max_open_sockets.set = 1536
        network.http.max_open.set = 48
        network.send_buffer.size.set = 128M
        network.receive_buffer.size.set = 4M

        ### Memory Settings
        pieces.hash.on_completion.set = no
        pieces.preload.type.set = 1

        ### add more torrents at once
        network.xmlrpc.size_limit.set = 5M
      '';
    };
    services.lighttpd = {
      enable = true;
      enableModules = ["mod_fastcgi"];
      document-root = "/home/www";
      extraConfig = ''
        server.bind = "localhost"
        fastcgi.server =  ( ".php" =>
            (("bin-path" => "${pkgs.php}/bin/php-cgi",
               "socket" => "/tmp/lighttpd-php-fastcgi-rutorrent.socket")))
      '';
    };
    users.users = {
      root = {
        initialHashedPassword = "$y$j9T$odRyg2xqJbySHei1UBsw3.$AxuY704CGICLQqKPm3wiV/b7LVOVSMKnV4iqK1KvAk2";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEeuanloGpRSuYbfJV3eGnfgyX1djaGC7UjUSgJeraKM openpgp:0x5862BCF8"
        ];
      };
      our = {
        isNormalUser = true;
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1craole2EAAAADAQABAAABgQDTc3A1qJl/v0Fkm3MgVom6AaYeSHr7GMHMWgYLzCAAPmfmZBEc3YWNTjnwinGHfuTun5F8hIwg1I/Of0wUYKNwH4Fx7fWQfOkOPxdeVLvy5sHVskwEMYeYteG4PPSDPqov+lQ6jYdL7KjlqQn4nLG5jLQsj47/axwBtdE5uS13cGOnyIuIq3O3djIWWOPv2RWEnc/xHHvsISg6e4HNZJr3W0AOcdd5NPk5Mf9BVj45kdR5TpypvPdTdI5jXYSmlousd5V2dNKqreBj7RX3Fap/vSViPM8EEbgFPC1i7hOWlWTMt12baAFFKZwRvjD6kr/FjUbGzh6Yx14NzJM+yFjwla71nbancL9kQr8S3WBF3OVLT26X43PltiVSfOPR7xsVx5pGbaesEuUPB6b394Z0w3zXAuQANwQbJZTDmjyvPvMDlEDwtoq/wQJvzwfi/n1NTimu3yjWvKFYTMPVH5HUQqj7FrG2c8aldAl18Z+dV/Mymky7CGIgHtT/oG99TSk= comment"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEeuanloGpRSuYbfJV3eGnfgyX1djaGC7UjUSgJeraKM openpgp:0x5862BCF8"
        ];
      };
      craole = {
        isNormalUser = true;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEeuanloGpRSuYbfJV3eGnfgyX1djaGC7UjUSgJeraKM openpgp:0x5862BCF8"
        ];
      };
    };
    zfs-root = {
      networking.networkmanager.enable = false;
      boot = {
        devNodes = "/dev/disk/by-id/";
        immutable = true;
      };
      per-user.craole.modules = {
        hiddenServices.enable = true;
        emacs.enable = true;
        tmux.enable = true;
      };
    };
    home-manager.users.craole = {
      home = {
        username = "craole";
        homeDirectory = mkDefault "/home/craole";
        stateVersion = mkDefault "22.11";
      };
      programs.home-manager.enable = true;
      xdg.configFile = {
        "pyrosimple/config.toml" = {source = ./pyrosimple-config.toml;};
      };
    };
    services.openssh = {
      ports = [22 65222];
      allowSFTP = true;
      openFirewall = true;
    };
    nix.settings.substituters = ["https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"];
    services.yggdrasil.persistentKeys = true;
    boot.initrd.secrets = {"/oldroot/etc/zfs-key-rpool-data-file" = null;};
    services.tor = {
      relay = {
        enable = false;
        onionServices = {
          ssh = {
            authorizedClients = [];
            map = [
              {
                port = 22;
                target = {
                  addr = "[::1]";
                  port = 22;
                };
              }
            ];
          };
        };
      };
      settings = {
        ClientUseIPv6 = true;
        ClientPreferIPv6ORPort = true;
        ClientUseIPv4 = true;
        UseBridges = 1;
        Bridge = [
          # see https://bridges.torproject.org/bridges/?transport=0&ipv6=yes
          # no javascript needed on that page
          "[2a03:4000:65:b0a:541c:a0ff:fec1:6737]:9010 B896373B1049FC39797A690B6A86503DB768150F"
          "[2001:41d0:800:60d::ff]:9001 59F622BDF6888CE480038F899CBCC2B7438B19A3"
        ];
      };
    };
    services.i2pd.inTunnels = {
      ssh-server = {
        enable = true;
        address = "::1";
        destination = "::1";
        #keys = "‹name›-keys.dat";
        #key is generated if missing
        port = 65222;
        accessList = []; # to lazy to only allow zfs-root laptops
      };
    };
    environment.systemPackages =
      builtins.attrValues {inherit (pkgs) smartmontools darkhttpd;};
    environment.loginShellInit = ''
      Nu () {
        source /etc/os-release
        nix-channel --add https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixos-"$VERSION_ID" nixos
        nix-channel --update
      }
      dsrv () {
        darkhttpd . --addr ::1 --ipv6 --port 8088
      }
      Nb () {
        if test -z "$TMUX"; then
           echo 'not in tmux';
           return 1
        fi
        nixos-rebuild boot \
         --option substituters https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store \
         --flake git+file:///home/craole/githost/systemConfiguration
      }
      Ns () {
        if test -z "$TMUX"; then
           echo 'not in tmux';
           return 1
        fi
        nixos-rebuild switch \
         --option substituters https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store \
         --flake git+file:///home/craole/githost/systemConfiguration
      }
      tm () {
         tmux attach-session
      }
      e () {
        $EDITOR $@
      }
    '';
    swapDevices = [];
  };
}
