_: {
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  systemd.tmpfiles.rules = [
    "d /home/craole/data 0750 craole craole -"
    "d /home/craole/data/hindsight 0750 1000 1000 -"
    "d /home/craole/.config/hindsight 0700 craole craole -"
  ];

  virtualisation.oci-containers.containers.hindsight = {
    autoStart = true;
    image = "ghcr.io/vectorize-io/hindsight:0.9.1";
    environmentFiles = ["/home/craole/.config/hindsight/hindsight.env"];
    ports = [
      "127.0.0.1:8888:8888"
      "127.0.0.1:9999:9999"
    ];
    volumes = ["/home/craole/data/hindsight:/home/hindsight/.pg0"];
    extraOptions = ["--user=1000:1000"];
    environment = {
      HINDSIGHT_API_LLM_PROVIDER = "openai";
      HINDSIGHT_API_LLM_BASE_URL = "http://100.76.128.70:20128/v1";
      HINDSIGHT_API_LLM_MODEL = "auto/best-fast";
      HINDSIGHT_API_RETAIN_LLM_MODEL = "auto/best-fast";
      HINDSIGHT_API_CONSOLIDATION_LLM_MODEL = "auto/best-fast";
      HINDSIGHT_API_REFLECT_LLM_MODEL = "auto/best-chat";
      HINDSIGHT_API_WORKER_ID = "victus-hindsight";
      HINDSIGHT_API_TENANT_EXTENSION = "hindsight_api.extensions.builtin.tenant:ApiKeyTenantExtension";
      HINDSIGHT_CP_DATAPLANE_API_URL = "http://localhost:8888";
    };
  };
}
