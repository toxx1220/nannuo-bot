{
  config,
  pkgs,
  lib,
  ...
}:
# Common Configuration - Provider Agnostic
let
  user = "toxx";
  sshPort = 22;
in
{
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 8d";
    };
  };

  users.users.${user} = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.user_password_hash.path;
    extraGroups = [
      "wheel"
    ];
    packages = with pkgs; [ ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK4j93LcS5wmBII8I+9A7m1hg/OTa0GMuB2HHDuCAOpy nobehm@gmail.com"
    ];
  };

  nix.settings = {
    # Use binary cache to avoid cross-compilation build errors
    substituters = [ "https://mic92.cachix.org" ];
    trusted-public-keys = [ "mic92.cachix.org-1:gi8IhgiT3CYZnJsaW7fxznzTkMUOn1RY4GmXdT/nXYQ=" ];
  };

  environment.systemPackages = with pkgs; [
    micro
    btop
    tree
    age
    sops
    git
  ];

  time.timeZone = "Europe/Berlin";

  boot.tmp.cleanOnBoot = true;
  boot.kernelParams = [
    "panic=1"
    "boot.panic_on_fail"
  ];

  networking = {
    networkmanager.enable = false;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        sshPort
      ];
    };
  };

  services.fail2ban.enable = true;

  services.openssh = {
    enable = true;
    ports = [ sshPort ];
    settings = {
      AllowUsers = [ user ];
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    extraConfig = ''
      ClientAliveInterval 3600
      ClientAliveCountMax 3
    '';
    banner = ''

         ____  ____ _____  ____  __  ______
        / __ \/ __ `/ __ \/ __ \/ / / / __ \
       / / / / /_/ / / / / / / / /_/ / /_/ /
      /_/ /_/\__,_/_/ /_/_/ /_/\__,_/\____/

    '';
  };

  system.stateVersion = "23.11";

  # SOPS Secrets Management
  sops.defaultSopsFile = ./secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  sops.secrets.discord_token = {
    owner = "nannuo"; # Ensure the bot user can read it
    # Restart the service if the token changes
    restartUnits = [ "nannuo-bot.service" ];
  };

  sops.secrets.user_password_hash = {
    neededForUsers = true;
  };

  # Nannuo Bot Service
  services.nannuo-bot = {
    enable = true;
    jarPath = "/var/lib/nannuo-bot/server.jar";
    tokenFile = config.sops.secrets.discord_token.path;
  };

  # General Server Optimizations
  nix.optimise.automatic = true;
  documentation.enable = false;
}
