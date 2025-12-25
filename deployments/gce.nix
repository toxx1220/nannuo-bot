{ config, pkgs, lib, modulesPath, ... }: {
   description = "GCE specific configuration";

  imports = [
    ./hardware-configuration.nix
    "${modulesPath}/virtualisation/google-compute-image.nix"
  ];

  # Bootloader
  boot.loader.grub.device = lib.mkForce "nodev";

  # Filesystem Layout
  fileSystems."/" = lib.mkForce {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  # Networking (GCE Specific Hostname/Domain)
  networking.hostName = "nannuo-instance";
  networking.domain = "us-central1-c.c.nomadic-bedrock-482308-a8.internal";
}
