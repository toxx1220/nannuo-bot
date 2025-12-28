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
    extraGroups = [
      "wheel"
      "sudo"
      "docker"
    ]; # Enable ‘sudo’ for the user.
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

  services.openssh = {
    enable = true;
    ports = [ sshPort ];
    settings = {
      AllowUsers = [ user ];
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      UsePAM = false;
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

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK4j93LcS5wmBII8I+9A7m1hg/OTa0GMuB2HHDuCAOpy nobehm@gmail.com"
    # Added by Google
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBN7ZPWWpZ8MG50/er8QqCpm/PIQF9biQnorl6BzDG1iik0w7e57FxvYi7RXrjBUgsOV8mw9h/tu9wkJauFIQ3SM= google-ssh {userName:nobehm@gmail.com,expireOn:2025-12-25T09:12:50+0000}"
    # Added by Google
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAFaILH0Bg5w/VQI0G7vx43+ADEkHCW0HF5g0WMj/HmYyZzGDYF8+Jq1nhkFivx0WuJLfvE0dpbPY4V60eFdXWeN2B4PmHLEv2S8BQaXHRwHBwj93D6sD+7cmcKTgQy7iVb7h4gnIzsTuM1fGG/esFc4iRTmT3+cZIIzWGE/GxjTUSvHiJZoDo/RYtLlEtaPvQgl7WyRKWo21zUJoEwQvhBWdtsbKIiSSDlomu/Z0S9rY5SbFvye0P/PLlZcvtfMVs7wMV6sxx1sy9mT0zg+Drhq0wWkG3npwsbE1aoR92sQZ4jUHs0nx15DYwlcZ3purhcj21MZStJ4YbgLWMX7eKW8= google-ssh {userName:nobehm@gmail.com,expireOn:2025-12-25T09:12:56+0000}"
  ];

  system.stateVersion = "23.11";

  # ============================================================================
  # SOPS Secrets Management
  # ============================================================================

  sops.defaultSopsFile = ./secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  # Use the server's SSH host key to decrypt secrets at runtime
  # This means you don't need to manually copy keys to the server,
  # just add the server's public SSH key (converted to age) to .sops.yaml
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  sops.secrets.discord_token = {
    owner = "nannuo"; # Ensure the bot user can read it
    # Optional: Restart the service if the token changes
    # restartUnits = [ "nannuo-bot.service" ];
  };

  # ============================================================================
  # Nannuo Bot Service
  # ============================================================================

  services.nannuo-bot = {
    enable = true;
    jarPath = "/var/lib/nannuo-bot/server.jar";
    # Point to the decrypted secret path managed by SOPS
    tokenFile = config.sops.secrets.discord_token.path;
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10s";
      MemoryMax = "650M";
    };
  };
}
