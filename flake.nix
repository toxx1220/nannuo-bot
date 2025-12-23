{
  description = "Nannuo Bot - A robust Discord bot in Kotlin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, ... }:
        let
          jdk = pkgs.jdk25;
        in
        {
          devShells.default = pkgs.mkShell {
            buildInputs = [
              jdk
              pkgs.gradle_9
            ];

            shellHook = ''
              export JAVA_HOME=${jdk}
              # For IntelliJ to pick up the JDK path easily if needed
              export GRADLE_OPTS="-Dorg.gradle.java.home=${jdk}"

              echo "🤖 Nannuo Bot Dev Environment"
              echo "Java: ${jdk.version}"
              echo "Gradle: $(gradle --version | grep Gradle | head -n 1)"
            '';
          };
        };

      flake = {
        nixosModules.default = { config, lib, pkgs, ... }:
          let
            cfg = config.services.nannuo-bot;
            jdk = pkgs.jdk25;
          in {
            options.services.nannuo-bot = {
              enable = lib.mkEnableOption "Nannuo Bot Service";

              jarPath = lib.mkOption {
                type = lib.types.path;
                default = "/var/lib/nannuo-bot/server.jar";
                description = "Location of the bot jar file (uploaded via SCP/Github)";
              };

              tokenFile = lib.mkOption {
                type = lib.types.path;
                description = "Path to a file containing the DISCORD_TOKEN";
              };
            };

            config = lib.mkIf cfg.enable {
              users.users.nannuo = {
                isSystemUser = true;
                group = "nannuo";
                description = "Nannuo Bot Service User";
                home = "/var/lib/nannuo-bot";
                createHome = true;
              };
              users.groups.nannuo = {};

              # Systemd Service
              systemd.services.nannuo-bot = {
                description = "Nannuo Discord Bot";
                after = [ "network.target" ];
                wantedBy = [ "multi-user.target" ];

                serviceConfig = {
                  User = "nannuo";
                  Group = "nannuo";
                  WorkingDirectory = "/var/lib/nannuo-bot";

                  EnvironmentFile = cfg.tokenFile;

                  ExecStart = "${jdk}/bin/java -jar ${cfg.jarPath}";

                  # Restart policy
                  Restart = "always";
                  RestartSec = "10s";
                };
              };
            };
          };
      };
    };
}
