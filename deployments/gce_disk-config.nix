{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            swap = {
              priority = 2;
              name = "swap";
              start = "500M";
              end = "2.5G"; # Defines a 2GB Swap
              content = {
                type = "swap";
                discardPolicy = "both";
                resumeDevice = true; # Allows hibernation if needed
              };
            };
            root = {
              priority = 3;
              name = "root";
              start = "2.5G";
              end = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
