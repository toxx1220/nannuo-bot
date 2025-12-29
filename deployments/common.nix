{
  config,
  pkgs,
  lib,
  ...
}:
# ============================================================================
# Common Configuration - Provider Agnostic
# ============================================================================
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
    # hashedPasswordFile = config.sops.secrets.user_password_hash.path;
    initialPassword = "password";
    extraGroups = [
      "wheel"
      "sudo"
      "docker"
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
  ];

  time.timeZone = "Europe/Berlin";

  boot.tmp.cleanOnBoot = true;

  networking = {
    networkmanager.enable = true;
    firewall.allowedTCPPorts = [
      80
      443
      sshPort
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK4j93LcS5wmBII8I+9A7m1hg/OTa0GMuB2HHDuCAOpy nobehm@gmail.com"
  ];

  services.openssh = {
    enable = true;
    ports = [ sshPort ];
    settings = {
      # AllowUsers = [ user "root" ];
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  system.stateVersion = "23.11";

  # SOPS Secrets Management
  sops.defaultSopsFile = ./secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  sops.secrets.discord_token = {
    owner = "root"; # Changed from "nannuo" for debugging
    # Restart the service if the token changes
    restartUnits = [ "nannuo-bot.service" ];
  };

  sops.secrets.user_password_hash = {
    neededForUsers = true;
  };

  # ============================================================================
  # Nannuo Bot Service
  # ============================================================================

  services.nannuo-bot = {
    enable = false; # Temporarily disabled for debugging
    jarPath = "/var/lib/nannuo-bot/server.jar";
    tokenFile = config.sops.secrets.discord_token.path;
  };
}
