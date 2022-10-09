{ config, pkgs, ... }:
let
  networkInterface = "enp0s20f0u1";
in {
  imports =
    [
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # net
  networking.hostName = "srv2";
  networking.useDHCP = false;
  networking.interfaces."${networkInterface}".ipv4.addresses = [
    { address = "192.168.88.82"; prefixLength = 24; }
  ];
  networking.defaultGateway = "192.168.88.1";
  networking.nameservers = ["8.8.8.8"];
  networking.networkmanager.enable = true;


  # i18n
  time.timeZone = "Europe/Zagreb";
  i18n.defaultLocale = "en_US.utf8";
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  users.users.root = {
    openssh.authorizedKeys.keys =
      builtins.fromJSON(builtins.readFile ./runtime/sshAuthorizedKeys.json);
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
  ];

  services.openssh.enable = true;

  # wireguard
  networking.nat.enable = true;
  networking.nat.externalInterface = "${networkInterface}";
  networking.nat.internalInterfaces = [ "wg0" ];
  networking.firewall.allowedUDPPorts = [ 51820 ];

  networking.wg-quick.interfaces.wg0 = {
    address = [ "192.168.44.1/24" ];
    listenPort = 51820;
    postUp = ''
      ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT;
      ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -o ${networkInterface} -j MASQUERADE
    '';
    preDown = ''
      ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT;
      ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -o ${networkInterface} -j MASQUERADE
    '';

    privateKey = builtins.fromJSON(builtins.readFile ./runtime/wgPrivateKey.json).key;
    peers = builtins.fromJSON(builtins.readFile ./runtime/wgPeers.json);
  };


  services.cron = {
    enable = true;
    systemCronJobs = [
      "* * * * *	root	cat /sys/class/power_supply/BAT0/status | grep -qi discharging && date >> /root/bat0_discharging"
    ];
  };

  system.stateVersion = "22.05";
}
