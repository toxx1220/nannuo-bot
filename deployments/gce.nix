{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    ./gce_disk-config.nix
    "${modulesPath}/virtualisation/google-compute-config.nix"
  ];

  # 1. Disk & Boot
  fileSystems."/".device = lib.mkForce "/dev/disk/by-partlabel/disk-main-root"; # prioritize disko setup
  boot.loader.grub = {
    device = lib.mkForce "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # 2. Tuning for Low Resource (1GB RAM)
  zramSwap = {
    enable = true;
    memoryPercent = 50; # Compress up to 500MB of RAM
    priority = 100;
  };

  nix.settings = {
    cores = 1;
    max-jobs = 1;
    auto-optimise-store = lib.mkForce false; # Save CPU during deploys
  };

  # 3. Low Maintenance: Auto Updates & Garbage Collection
  system.autoUpgrade = {
    enable = true;
    # Check for updates daily between 04:00 and 05:00
    dates = "04:00";
    # Pull directly from repo.
    # Ensure repo is public OR git keys are configured on the server.
    flake = "github:toxx1220/nannuo-bot#gce-x86";
    flags = [
      "--update-input"
      "nixpkgs"
      "--commit-lock-file"
    ];
    allowReboot = true; # Reboot if kernel updates
  };

  # Aggressive GC to keep disk usage low on the small VM
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 3d";
  };
  nix.optimise.automatic = true; # Deduplicate files nightly

  # 4. Service Tuning
  systemd.services.nannuo-bot = {
    environment = {
      # -XX:+UseSerialGC: Use the simplest Garbage Collector (lowest RAM overhead).
      # -XX:MaxRAMPercentage: Fallback if Xmx isn't respected.
      "JAVA_TOOL_OPTIONS" = "-Xmx600m -XX:+UseSerialGC -XX:MaxRAMPercentage=75.0";
    };

    serviceConfig = {
      Restart = lib.mkForce "on-failure";
      RestartSec = "10s";

      # Hard Service limit
      MemoryMax = "800M";

      # Hardening
      ProtectSystem = "full";
      ProtectHome = true;
    };
  };

  documentation.enable = false; # Save space

  networking = {
    hostName = "nannuo-instance";
    domain = "us-central1-c.c.nomadic-bedrock-482308-a8.internal";
    firewall.enable = lib.mkForce true; # Google config might disable firewall by default
  };
}
