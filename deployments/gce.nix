{ config, pkgs, lib, modulesPath, ... }: {
 # GCE specific configuration

  imports = [
    ./gce_disk-config.nix
    "${modulesPath}/virtualisation/google-compute-config.nix"
  ];

  fileSystems."/".device = lib.mkForce "/dev/disk/by-partlabel/disk-main-root"; # prioritize disko setup

  boot.loader.grub = {
    device = lib.mkForce "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # Networking (GCE Specific Hostname/Domain)
  networking = {
    hostName = "nannuo-instance";
    domain = "us-central1-c.c.nomadic-bedrock-482308-a8.internal";
    firewall.enable = lib.mkForce true; # Google config might disable firewall by default
  };
}
