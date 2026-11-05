{mergeDisjoint,
  mkAliasFamily,
  mkSource,
  ...
}: {
  curl = mkSource {
    categories = ["networking" "scripting"];
    description = "transfer data with URLs";
    aliases = mkAliasFamily "curl" {
      fsSL = {
        args = ["-fsSL"];
        description = "fetch quietly, follow redirects, and fail on HTTP errors";
      };
      I = {
        args = ["--head"];
        description = "fetch response headers only";
      };
      Json = {
        args = ["-fsSL" "-H" "Accept: application/json"];
        description = "fetch quietly while requesting a JSON response";
      };
      L = {
        args = ["--location"];
        description = "follow redirects";
      };
      O = {
        args = ["--remote-name"];
        description = "save the download using its remote file name";
      };
      Output = {
        args = ["--output"];
        description = "save the download to a caller-specified path";
      };
      Retry = {
        args = ["-fsSL" "--retry" "3" "--retry-delay" "2"];
        description = "fetch quietly and retry transient failures up to three times";
      };
    };
  };

  iproute2 = mkSource {
    categories = ["networking" "scripting"];
    description = "ip, ss, bridge, and related networking tools";
    discover = true; #? ip, ss, bridge, ...
    exe = "ip";
    aliases = mergeDisjoint [
      (mkAliasFamily "ip" {
        "4" = {
          args = ["-4"];
          description = "limit output to IPv4";
        };
        "6" = {
          args = ["-6"];
          description = "limit output to IPv6";
        };
        BrAddr = {
          args = ["-brief" "address"];
          description = "show a compact table of interface addresses";
        };
        BrLink = {
          args = ["-brief" "link"];
          description = "show a compact table of interface link states";
        };
        Json = {
          args = ["-json"];
          description = "output JSON";
        };
        Neigh = {
          args = ["neighbour" "show"];
          description = "show the neighbour (ARP/NDP) table";
        };
        Route = {
          args = ["route" "show"];
          description = "show the routing table";
        };
      })
      (mkAliasFamily "ss" {
        Listen = {
          args = ["-tulpn"];
          description = "show listening TCP and UDP sockets with processes and numeric ports";
        };
        Summary = {
          args = ["--summary"];
          description = "show socket statistics";
        };
      })
    ];
  };
}
