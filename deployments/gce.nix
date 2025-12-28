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
    cores = 1; # Single core build to save RAM
    max-jobs = 1;
    auto-optimise-store = lib.mkForce false; # Save CPU during deploys
  };

  # Run optimization at night instead
  nix.optimise.automatic = true;

  # 3. Low Maintenance: Auto Updates & Garbage Collection
  system.autoUpgrade = {
    enable = true;
    dates = "04:00";
    flake = "github:toxx1220/nannuo-bot#gce-x86";
    flags = [
      "--update-input"
      "nixpkgs"
      "--commit-lock-file"
    ];
    allowReboot = true; # Reboot if kernel updates
  };

  # 4. Service Tuning
  systemd.services.nannuo-bot = {
    environment = {
      # -Xmx600m: Leave ~400MB for OS overhead + ZRAM
      # -XX:+UseSerialGC: Low overhead GC for single-core/low-RAM
      "JAVA_TOOL_OPTIONS" = "-Xmx600m -XX:+UseSerialGC";
    };

    serviceConfig = {
      # Hard Limit: Kill if it goes beyond 800MB
      MemoryMax = "800M";
    };
  };

  documentation.enable = false; # Save space

  networking = {
    hostName = "nannuo-instance";
    domain = "us-central1-c.c.nomadic-bedrock-482308-a8.internal";
    firewall.enable = lib.mkForce true; # Google config might disable firewall by default
  };
}
