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
    # "${modulesPath}/virtualisation/google-compute-config.nix" # DISABLED: Breaks manual SSH/User management
  ];

  # GCE Specific Hardware & Boot
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
  ];

  # GCE Specific Networking (Systemd-Networkd)
  # Disable NetworkManager in favor of systemd-networkd for server reliability
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
    # GCE internal domain - Note: This is project/zone specific.
    # If redeploying to a different project or zone, update this accordingly.
    domain = "us-central1-c.c.nomadic-bedrock-482308-a8.internal";
  };

  # Resource Tuning (1GB RAM Optimization)
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

  # Service Tuning for 1GB RAM
  systemd.services.nannuo-bot = {
    environment = {
      "JAVA_TOOL_OPTIONS" = "-Xmx600m -XX:+UseSerialGC";
    };
    serviceConfig = {
      MemoryMax = "800M";
    };
  };
}
