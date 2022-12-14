{ pkgs, modulesPath, ... }:
{
  imports = [ "${modulesPath}/virtualisation/azure-common.nix" ];

  ##############################################################################
  # system

  users.users.dumpovac = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuAQ43SM0EVulTuivIuAGI0P2RcREUY0nTRtlolZDZ bartol@dump.hr"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID1hZ9VMu7F/ap5ho9ymWuDUshoOWalBTtomsY/wH97x dujesa@dump.hr"
    ];
  };
  users.users.root = {
    openssh.authorizedKeys.keys = builtins.fromJSON ''<%
      bw list items --collectionid 927a8631-da7c-4197-a0ff-8b8bf19c967c \
      | jq '[.[].fields[]|select(.name=="sshPublicKey").value]'
    %>'';
  };
  services.openssh.passwordAuthentication = false;
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    vim git tmux htop curl wget
  ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  system.stateVersion = "22.05";

  ##############################################################################
  # containers

  system.activationScripts.vaultwarden-net = ''
    ${pkgs.docker}/bin/docker network inspect vaultwarden &>/dev/null ||
    ${pkgs.docker}/bin/docker network create vaultwarden --subnet 172.20.0.0/16
  '';

  virtualisation.docker.enable = true;
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      vaultwarden-db = {
        image = "postgres:14";
        environment = {
          POSTGRES_DB = "vaultwarden";
          POSTGRES_USER = "vaultwarden";
          POSTGRES_PASSWORD = "vaultwarden";
        };
        volumes = [
          "/home/dumpovac/vaultwarden-pgdata:/var/lib/postgresql/data"
        ];
        ports = [
          "5432:5432"
        ];
        extraOptions = [ "--network=vaultwarden" ];
      };

      vaultwarden-app = {
        image = "vaultwarden/server:latest";
        environment = {
          DOMAIN = "https://bitwarden.dump.hr";
          DATABASE_URL = "postgres://vaultwarden:vaultwarden@vaultwarden-db:5432/vaultwarden";
          SIGNUPS_ALLOWED = "false";
          SMTP_FROM = "bitwarden@dump.hr";
          SMTP_HOST = "smtp.office365.com";
          SMTP_PORT = "587";
          SMTP_SECURITY = "starttls";
          SMTP_USERNAME = "bitwarden@dump.hr";
          SMTP_PASSWORD = ''<%
            bw get item 3ce68dc6-de4a-407e-949f-41220c3aa242 \
            | jq -j '.login.password'
          %>'';
        };
        volumes = [
          "/home/dumpovac/vaultwarden-appdata:/data"
        ];
        ports = [
          "4000:80"
        ];
        extraOptions = [ "--network=vaultwarden" ];
        dependsOn = [ "vaultwarden-db" ];
      };
    };
  };

  ##############################################################################
  # services

  security.acme = {
    acceptTerms = true;
    defaults.email = "sysadmin@dump.hr";
  };
  
  services.nginx = {
    enable = true;
    virtualHosts."bitwarden.dump.hr" = {
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:4000";
    };
  };
}
