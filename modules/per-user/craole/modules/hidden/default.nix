{
  config,
  lib,
  ...
}: let
  cfg = config.zfs-root.per-user.craole.modules.hiddenServices;
  inherit (lib) mkDefault mkOption types mkIf mkMerge;
in {
  options.zfs-root.per-user.craole.modules.hiddenServices = {
    enable = mkOption {
      type = types.bool;
      default = config.zfs-root.per-user.craole.enable;
    };
    resolv = mkOption {
      type = types.bool;
      default = config.zfs-root.per-user.craole.modules.hiddenServices.enable;
    };
  };
  config = mkIf (cfg.enable) (mkMerge [
    {
      services = {
        tor = {
          enable = true;
          client = {
            enable = true;
            dns.enable = true;
          };
          settings = {
            Sandbox = true;
            SafeSocks = 1;
            NoExec = 1;
          };
          torsocks = {
            enable = true;
            server = "127.0.0.1:9050";
          };
        };
        i2pd = {
          enable = true;
          enableIPv4 = true;
          enableIPv6 = true;
          bandwidth = 4096;
          port = 29392;
          proto = {
            http = {
              port = 7071;
              enable = true;
            };
            socksProxy.port = 4447;
            socksProxy.enable = true;
          };
          floodfill = true;
          inTunnels = {};
          outTunnels = {
            # connect to mail services by postman
            # available at http://hq.postman.i2p
            smtp-postman = {
              enable = true;
              address = "::1";
              destinationPort = 7659;
              destination = "smtp.postman.i2p";
              port = 7659;
            };
            pop-postman = {
              enable = true;
              address = "::1";
              destinationPort = 7660;
              destination = "pop.postman.i2p";
              port = 7660;
            };
          };
        };

        yggdrasil = {
          enable = true;
          openMulticastPort = false;
          settings.Peers = [
            #curl https://publicpeers.neilalexander.dev/ | grep "<td id='status'>online</td><td id='reliability'>reliable</td>" | sed "s|</td><td id='version'>.*|\"|" | sed "s|<td id='address'>|\"|" | sort | wl-copy -n
            "tcp://158.101.229.219:17002"
            "tcp://185.165.169.234:8880"
            "tcp://193.107.20.230:7743"
            "tcp://193.111.114.28:8080"
            "tcp://[2603:c023:8001:1600:35e0:acde:2c6e:b27f]:17002"
            "tcp://[2a00:b700::a:279]:12402"
            "tcp://[2a09:5302:ffff::992]:12403"
            "tcp://45.147.200.202:12402"
            "tcp://45.95.202.21:12403"
            "tcp://50.236.201.218:56088"
            "tcp://51.15.204.214:12345"
            "tcp://77.37.218.131:12402"
            "tls://102.223.180.74:993"
            "tls://108.175.10.127:61216"
            "tls://152.228.216.112:23108"
            "tls://158.101.229.219:17001"
            "tls://167.160.89.98:7040"
            "tls://185.103.109.63:65535"
            "tls://185.130.44.194:7040"
            "tls://185.165.169.234:8443"
            "tls://185.175.90.87:43006"
            "tls://192.99.145.61:58226"
            "tls://193.111.114.28:1443"
            "tls://[2001:41d0:2:c44a:51:255:223:60]:54232"
            "tls://[2001:41d0:304:200::ace3]:23108"
            "tls://23.137.249.65:443"
            "tls://[2603:c023:8001:1600:35e0:acde:2c6e:b27f]:17001"
            "tls://[2605:9f80:2000:64::2]:7040"
            "tls://[2607:5300:201:3100::50a1]:58226"
            "tls://[2a00:b700::a:279]:443"
            "tls://[2a01:4f9:2a:60c::2]:18836"
            "tls://[2a01:4f9:c010:664d::1]:61995"
            "tls://[2a07:e01:105:444:c634:6bff:feb5:6e28]:7040"
            "tls://[2a09:5302:ffff::992]:443"
            "tls://[2a09:5302:ffff::aca]:65535"
            "tls://[2a10:4740:40:0:2222:3f9c:b7cf:1]:43006"
            "tls://45.147.200.202:443"
            "tls://45.95.202.21:443"
            "tls://45.95.202.91:65535"
            "tls://51.15.204.214:54321"
            "tls://51.255.223.60:54232"
            "tls://51.38.64.12:28395"
            "tls://54.37.137.221:11129"
            "tls://65.21.57.122:61995"
            "tls://77.37.218.131:443"
            "tls://94.103.82.150:8080"
            "tls://94.140.114.241:4708"
            "tls://95.216.5.243:18836"
          ];
        };
      };
      networking.hosts = {
        "200:8bcd:55f4:becc:4d85:2fa6:2ed2:5eba" = ["tl.craole"];
      };
    }
    (mkIf cfg.resolv {
      networking.nameservers = ["::1"];
      services.dnscrypt-proxy2 = {
        enable = true;
        settings = {
          listen_addresses = ["127.0.0.1:53" "[::1]:53"];
          max_clients = 250;
          # https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v3/public-resolvers.md
          server_names = [
            "dns0"
            "scaleway-fr"
            "google"
            "google-ipv6"
            "cloudflare"
            "dct-de1"
            "dns.digitalsize.net"
            "dns.digitalsize.net-ipv6"
            "dns.watch"
            "dns.watch-ipv6"
            "dnscrypt-de-blahdns-ipv4"
            "dnscrypt-de-blahdns-ipv6"
            "doh.ffmuc.net"
            "doh.ffmuc.net-v6"
            "he"
            "dnsforge.de"
            "bortzmeyer"
            "bortzmeyer-ipv6"
            "circl-doh"
            "circl-doh-ipv6"
            "cloudflare-ipv6"
            "dns.digitale-gesellschaft.ch-ipv6"
            "dns.digitale-gesellschaft.ch"
          ];
          ipv4_servers = true;
          ipv6_servers = false;
          dnscrypt_servers = true;
          doh_servers = true;
          odoh_servers = false;
          require_dnssec = false;
          require_nolog = true;
          require_nofilter = true;
          disabled_server_names = [];
          force_tcp = false;
          http3 = false;
          timeout = 5000;
          keepalive = 30;
          cert_refresh_delay = 240;
          bootstrap_resolvers = ["9.9.9.11:53" "8.8.8.8:53"];
          ignore_system_dns = true;
          netprobe_timeout = 60;
          netprobe_address = "9.9.9.9:53";
          log_files_max_size = 10;
          log_files_max_age = 7;
          log_files_max_backups = 1;
          block_ipv6 = false;
          block_unqualified = true;
          block_undelegated = true;
          reject_ttl = 10;
          cache = true;
          cache_size = 4096;
          cache_min_ttl = 2400;
          cache_max_ttl = 86400;
          cache_neg_min_ttl = 60;
          cache_neg_max_ttl = 600;
          sources.public-resolvers = {
            urls = [
              "https://download.dnscrypt.info/resolvers-list/v2/public-resolvers.md"
              "https://ipv6.download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
            ];
            cache_file = "public-resolvers.md";
            minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
            refresh_delay = 72;
          };
          sources.relays = {
            urls = [
              "https://download.dnscrypt.info/resolvers-list/v3/relays.md"
              "https://ipv6.download.dnscrypt.info/resolvers-list/v3/relays.md"
            ];
            cache_file = "relays.md";
            minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
            refresh_delay = 72;
          };
          query_log.file = "query.log";
          query_log.format = "tsv";
          anonymized_dns.skip_incompatible = false;
          broken_implementations.fragments_blocked = [
            "cisco"
            "cisco-ipv6"
            "cisco-familyshield"
            "cisco-familyshield-ipv6"
            "cleanbrowsing-adult"
            "cleanbrowsing-adult-ipv6"
            "cleanbrowsing-family"
            "cleanbrowsing-family-ipv6"
            "cleanbrowsing-security"
            "cleanbrowsing-security-ipv6"
          ];
        };
        upstreamDefaults = false;
      };
    })
  ]);
}
