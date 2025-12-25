{ config, pkgs, lib, ... }: {
  description = "Provider Agnostic Configuration";

  nix.settings = {
    cores = 1;
    max-jobs = 1;
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
  };

  # When low on memory
  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;
  swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 2048;
  }];

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK4j93LcS5wmBII8I+9A7m1hg/OTa0GMuB2HHDuCAOpy nobehm@gmail.com"
    # Added by Google
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBN7ZPWWpZ8MG50/er8QqCpm/PIQF9biQnorl6BzDG1iik0w7e57FxvYi7RXrjBUgsOV8mw9h/tu9wkJauFIQ3SM= google-ssh {userName:nobehm@gmail.com,expireOn:2025-12-25T09:12:50+0000}"
    # Added by Google
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAFaILH0Bg5w/VQI0G7vx43+ADEkHCW0HF5g0WMj/HmYyZzGDYF8+Jq1nhkFivx0WuJLfvE0dpbPY4V60eFdXWeN2B4PmHLEv2S8BQaXHRwHBwj93D6sD+7cmcKTgQy7iVb7h4gnIzsTuM1fGG/esFc4iRTmT3+cZIIzWGE/GxjTUSvHiJZoDo/RYtLlEtaPvQgl7WyRKWo21zUJoEwQvhBWdtsbKIiSSDlomu/Z0S9rY5SbFvye0P/PLlZcvtfMVs7wMV6sxx1sy9mT0zg+Drhq0wWkG3npwsbE1aoR92sQZ4jUHs0nx15DYwlcZ3purhcj21MZStJ4YbgLWMX7eKW8= google-ssh {userName:nobehm@gmail.com,expireOn:2025-12-25T09:12:56+0000}"
  ];

  system.stateVersion = "23.11";
}
