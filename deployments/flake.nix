{
  description = "Nannuo Bot VPS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Use "github:username/repo" for production/remote builds, root level flake will be used then
    nannuo-bot.url = "path:../";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, nannuo-bot, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      flake = {
        nixosConfigurations = {
          gce-x86 = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./common.nix
              ./gce.nix
              nannuo-bot.nixosModules.default
              ({ pkgs, ... }: {
                services.nannuo-bot = {
                  enable = true;
                  jarPath = "/var/lib/nannuo-bot/server.jar"; # expects jar here
                  # You must create this file manually on the server
                  tokenFile = "/var/lib/nannuo-bot/token.env";
                };
              })
            ];
          };
        };
      };
    };
}
