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

  # Ensure GVNIC and VirtIO drivers are available in initrd for Stage 1
  boot.initrd.availableKernelModules = [
    "virtio_net"
    "virtio_pci"
    "virtio_scsi"
    "virtio_blk"
    "gve"
    "nvme"
    "sd_mod"
  ];

  # Force inclusion of these modules to prevent "Can't lookup blockdev" errors
  boot.initrd.kernelModules = [
    "virtio_pci"
    "virtio_scsi"
    "virtio_blk"
    "sd_mod"
  ];

  # Enable Serial Console so we can see logs in GCE Console
  boot.kernelParams = [
    "console=ttyS0,115200"
    "earlyprintk=ttyS0,115200"
    "panic=1"
    "boot.panic_on_fail"
  ];

  # ============================================================================
  # 2. Networking (Systemd-Networkd)
  # ============================================================================
  # Disable NetworkManager in favor of systemd-networkd for server reliability
  networking.networkmanager.enable = lib.mkForce false;
  networking.useDHCP = lib.mkForce false;

  systemd.network = {
    enable = true;
    networks."10-wan" = {
      # Match ens4 (VirtIO) or gve0 (GVNIC)
      matchConfig.Name = [
        "e*"
        "g*"
      ];
      networkConfig.DHCP = "yes";
    };
  };

  networking = {
    hostName = "nannuo-instance";
    # GCE internal domain
    domain = "us-central1-c.c.nomadic-bedrock-482308-a8.internal";

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
      ];
    };
  };

  # ============================================================================
  # 3. Disk & Filesystem
  # ============================================================================
  # Disko handles the root mount automatically via gce_disk-config.nix

  # ============================================================================
  # 4. Resource Tuning (1GB RAM Optimization)
  # ============================================================================
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
  documentation.enable = false;

  # ============================================================================
  # 5. Service Tuning
  # ============================================================================
  systemd.services.nannuo-bot = {
    environment = {
      "JAVA_TOOL_OPTIONS" = "-Xmx600m -XX:+UseSerialGC";
      # -Xmx600m: Leave ~400MB for OS overhead + ZRAM
      # -XX:+UseSerialGC: Low overhead GC
    };
    serviceConfig = {
      MemoryMax = "800M";
    };
  };

  # ============================================================================
  # 6. Auto Updates
  # ============================================================================
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
}
