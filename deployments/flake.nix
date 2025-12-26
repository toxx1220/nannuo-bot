{
  description = "Nannuo Bot VPS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    sops-nix.url = "github:Mic92/sops-nix";

    # Import the bot flake from the parent directory
    # Use "github:username/repo" for production/remote builds
    nannuo-bot.url = "path:../";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, nannuo-bot, sops-nix, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      flake = {
        nixosConfigurations = {
          # 1. Google Cloud (x86_64)
          gce-x86 = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./common.nix
              ./gce.nix
              nannuo-bot.nixosModules.default
              sops-nix.nixosModules.sops
            ];
          };
        };
      };
    };
}
