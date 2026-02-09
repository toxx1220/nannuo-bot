{
  description = "nannuo bot development and deployment flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    git-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      sops-nix,
      disko,
      ...
    }:
    let
      # --- Source of Truth Extraction ---
      # We read from gradle.properties
      gradleProps = builtins.readFile ./gradle.properties;

      # Helper to extract a value from gradle.properties
      getProp =
        prop:
        let
          match = builtins.match ".*${prop}=([^ \n\r]+).*" (
            nixpkgs.lib.replaceStrings [ "\n" "\r" ] [ " " " " ] gradleProps
          );
        in
        if match != null then builtins.elemAt match 0 else null;

      javaVersion = getProp "javaVersion";
      projectVersion = getProp "projectVersion";

      lib = nixpkgs.lib;
    in

    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.git-hooks-nix.flakeModule ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        { config, pkgs, ... }:
        let
          jdk = pkgs."jdk${javaVersion}";
          jdk_headless = pkgs."jdk${javaVersion}_headless";
          gradle = pkgs.gradle_9;

          # --- Dependency Management ---
          # This is the "Lock" for your dependencies.
          # To update, run: nix run .#update-deps
          depsHashFile = ./deployments/deps-hash.nix;

          # We use a dummy hash if the file is missing to allow the update script to run.
          # This is a standard Nix pattern for bootstrapping Fixed-Output Derivations.
          currentHash = if builtins.pathExists depsHashFile then import depsHashFile else pkgs.lib.fakeHash;

          # This derivation fetches all dependencies into a reproducible archive
          nannuo-bot-deps = pkgs.stdenv.mkDerivation {
            pname = "nannuo-bot-deps";
            version = projectVersion;
            src = ./.;
            nativeBuildInputs = [
              jdk
              gradle
              pkgs.cacert
            ];

            # Disable the Nix Gradle setup hook — it injects --offline and an
            # init-script that interfere with dependency fetching in the FOD.
            dontUseGradleConfigure = true;

            buildPhase = ''
              export GRADLE_USER_HOME=$(pwd)/.gradle
              export JAVA_HOME=${jdk}

              # Point to CA certificates for HTTPS downloads
              export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
              export NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt

              # Generate JKS TrustStore from the CA bundle so Java/Gradle can
              # verify HTTPS certificates inside the sandbox.
              echo "Generating JKS TrustStore from CA bundle..."
              TRUSTSTORE="$(pwd)/truststore.jks"
              awk 'BEGIN{n=0} /-----BEGIN CERTIFICATE-----/{n++} {print > "cert-" n ".pem"}' \
                < ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
              imported=0
              for f in cert-*.pem; do
                ${jdk}/bin/keytool -importcert -trustcacerts -noprompt \
                  -keystore "$TRUSTSTORE" -storepass changeit \
                  -alias "$f" -file "$f" > /dev/null 2>&1 && imported=$((imported + 1))
              done
              echo "Imported $imported CA certificates into TrustStore."
              if [ "$imported" -eq 0 ]; then
                echo "FATAL: TrustStore is empty — no CA certs were imported."
                exit 1
              fi

              export GRADLE_OPTS="-Djavax.net.ssl.trustStore=$TRUSTSTORE -Djavax.net.ssl.trustStorePassword=changeit"

              # Run the actual build to resolve and cache all dependencies.
              # Use 'command gradle' to bypass any shell-function wrappers.
              command gradle --no-daemon shadowJar -x test --info
            '';
            installPhase = ''
              tar -cf $out .gradle/caches
            '';
            outputHashAlgo = "sha256";
            outputHashMode = "flat";
            outputHash = currentHash;
          };

          # --- Main Build ---
          nannuo-bot = pkgs.stdenv.mkDerivation {
            pname = "nannuo-bot";
            version = projectVersion;
            src = ./.;

            nativeBuildInputs = [
              jdk
              gradle
              pkgs.makeWrapper
            ];

            buildPhase = ''
              export GRADLE_USER_HOME=$(mktemp -d)
              export JAVA_HOME=${jdk}

              # Extract cached dependencies
              tar -xf ${nannuo-bot-deps} -C .
              cp -r .gradle/caches $GRADLE_USER_HOME/

              # Run in offline mode
              gradle shadowJar --no-daemon --offline
            '';

            installPhase = ''
              mkdir -p $out/share/java
              cp build/libs/*-all.jar $out/share/java/nannuo-bot.jar

              mkdir -p $out/bin
              makeWrapper ${jdk_headless}/bin/java $out/bin/nannuo-bot \
                --add-flags "-jar $out/share/java/nannuo-bot.jar"
            '';
          };

          # --- Automation Script ---
          update-deps = pkgs.writeShellApplication {
            name = "update-deps";
            runtimeInputs = [
              pkgs.nix
              pkgs.coreutils
            ];
            text = ''
              echo "🔄 Calculating new dependency hash..."
              echo "   (This may take a few minutes as it downloads dependencies)"

              # Use nix-build to get the mismatch error
              # We use --impure to allow some environment variables if needed, 
              # but FODs should work regardless.
              BUILD_RC=0
              OUT=$(nix build .#nannuo-bot-deps --no-link 2>&1) || BUILD_RC=$?

              if [ "$BUILD_RC" -eq 0 ]; then
                echo "✅ Dependencies are already up to date. No hash change needed."
                exit 0
              fi

              NEW_HASH=$(echo "$OUT" | grep "got:" | sed 's/.*got:[[:space:]]*//' | xargs || true)

              if [ -n "$NEW_HASH" ] && [[ "$NEW_HASH" == sha256-* ]]; then
                echo "✨ New hash found: $NEW_HASH"
                echo "\"$NEW_HASH\"" > deployments/deps-hash.nix
                echo "✅ deployments/deps-hash.nix updated!"
                
                # Automatically stage the change if in a git repo
                if [ -d .git ]; then
                  git add deployments/deps-hash.nix
                  echo "📝 Staged deployments/deps-hash.nix"
                fi
              else
                echo "❌ Could not automatically determine the new hash."
                echo "Error output was:"
                echo "$OUT"
              fi
            '';
          };

        in
        {
          formatter = pkgs.nixfmt-rfc-style;

          pre-commit.settings.hooks.nixfmt-rfc-style.enable = true;

          packages = {
            default = nannuo-bot;
            nannuo-bot-deps = nannuo-bot-deps;
            update-deps = update-deps;
          };

          devShells.default = pkgs.mkShell {
            packages = [
              jdk
              pkgs.gradle_9
              update-deps
            ];
            shellHook = ''
              # Install the pre-commit hooks
              ${config.pre-commit.installationScript}

              export JAVA_HOME=${jdk}
              # For IntelliJ to pick up the JDK path easily if needed
              export GRADLE_OPTS="-Dorg.gradle.java.home=${jdk}"

              echo "🤖 Nannuo Bot Dev Environment"
              echo "Java: ${jdk.version}"

              GRADLE_VERSION="${pkgs.gradle_9.version}"
              WRAPPER_PROPS="gradle/wrapper/gradle-wrapper.properties"

              if [ ! -f "$WRAPPER_PROPS" ] || ! grep -q "gradle-$GRADLE_VERSION-bin.zip" "$WRAPPER_PROPS"; then
                echo "🔄 Updating Gradle Wrapper to $GRADLE_VERSION..."
                gradle wrapper --gradle-version "$GRADLE_VERSION"
              else
                echo "✅ Gradle Wrapper is up to date ($GRADLE_VERSION)"
              fi
            '';
          };
        };

      flake = {
        nixosConfigurations = {
          gce-x86 = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./deployments/common.nix
              ./deployments/gce.nix
              self.nixosModules.default
              sops-nix.nixosModules.sops
              disko.nixosModules.disko
            ];
          };
        };

        nixosModules.default =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          let
            cfg = config.services.nannuo-bot;
            user = "nannuo";
          in
          {
            options.services.nannuo-bot = {
              enable = lib.mkEnableOption "Nannuo Bot Service";

              package = lib.mkOption {
                type = lib.types.package;
                default = self.packages.${pkgs.system}.default;
                description = "The nannuo-bot package to use.";
              };

              tokenFile = lib.mkOption {
                type = lib.types.str;
                description = "Path to a file containing the DISCORD_TOKEN (raw token or KEY=VALUE)";
              };
            };

            config = lib.mkIf cfg.enable {
              users.users.${user} = {
                isSystemUser = true;
                group = user;
                description = "Nannuo Bot Service User";
                home = "/var/lib/nannuo-bot";
                createHome = true;
              };
              users.groups.${user} = { };

              systemd.services.nannuo-bot = {
                description = "Nannuo Discord Bot";
                after = [ "network.target" ];
                wantedBy = [ "multi-user.target" ];

                serviceConfig = {
                  User = user;
                  Group = user;
                  WorkingDirectory = "/var/lib/nannuo-bot";
                  Environment = [ "DISCORD_TOKEN_PATH=${cfg.tokenFile}" ];
                  ExecStart = "${cfg.package}/bin/nannuo-bot";

                  Restart = "on-failure";
                  RestartSec = "10s";

                  # standard hardening
                  ProtectSystem = "full"; # Read-only /usr, /boot, /etc
                  ProtectHome = true; # Inaccessible /home
                  NoNewPrivileges = true; # Cannot escalate to root
                  PrivateTmp = true;
                };
              };
            };
          };
      };
    };
}
