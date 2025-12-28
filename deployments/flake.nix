{
  description = "nannuo bot VPS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    sops-nix.url = "github:Mic92/sops-nix";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nannuo-bot.url = "github:toxx1220/nannuo-bot";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, nannuo-bot, sops-nix, disko, ... }:
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
              disko.nixosModules.disko
            ];
          };
        };
      };
    };
}
