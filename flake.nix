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
      lib = nixpkgs.lib;

      # --- Source of Truth Extraction ---
      # We read from gradle.properties
      gradlePropsLines = lib.strings.splitString "\n" (builtins.readFile ./gradle.properties);

      # Helper to extract a value from gradle.properties
      getProp =
        prop:
        let
          line = lib.findFirst (l: lib.hasPrefix "${prop}=" l) null gradlePropsLines;
        in
        if line != null then lib.removePrefix "${prop}=" line else null;

      javaVersion = getProp "javaVersion";
      projectVersion = getProp "projectVersion";
      pname = getProp "rootProjectName";
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
          #
          # Gradle caches can differ per-OS/arch, so they need to be stored per system.
          depsHashDir = ./deployments/deps-hash;
          hostSystem = pkgs.stdenv.hostPlatform.system;
          depsHashFile = depsHashDir + "/${hostSystem}.nix";

          # Dummy hash to allow the script to run if file is missing
          currentHash = if builtins.pathExists depsHashFile then import depsHashFile else pkgs.lib.fakeHash;

          # This derivation fetches all dependencies into a reproducible archive
          nannuo-bot-deps = pkgs.stdenv.mkDerivation {
            pname = "${pname}-deps";
            version = projectVersion;
            src = ./.;
            nativeBuildInputs = [
              jdk
              gradle
              pkgs.cacert
            ];

            # Disable the Nix Gradle setup hook — it injects "--offline" and an
            # init-script that interfere with dependency fetching in the FOD.
            dontUseGradleConfigure = true;

            buildPhase = ''
              export GRADLE_USER_HOME=$(pwd)/.gradle
              export JAVA_HOME=${jdk}

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

            # The Gradle cache contains text references to Nix store paths (e.g., JDK paths
            # in cached metadata). These are not actual runtime dependencies, so ignoring them
            # is fine and prevents nix build errors.
            __structuredAttrs = true; # required to use unsafeDiscardReferences
            unsafeDiscardReferences.out = true;
          };

          # --- Main Build ---
          nannuo-bot = pkgs.stdenv.mkDerivation {
            pname = pname;
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
              cp build/libs/*-all.jar $out/share/java/${pname}.jar

              mkdir -p $out/bin
              makeWrapper ${jdk_headless}/bin/java $out/bin/${pname} \
                --add-flags "-jar $out/share/java/${pname}.jar"
            '';
          };

          # --- Update Dependency Automation ---
          update-deps = pkgs.writeShellApplication {
            name = "update-deps";
            runtimeInputs = [
              pkgs.nix
              pkgs.coreutils
              pkgs.git
            ];
            text = builtins.readFile ./scripts/update-deps.sh;
          };

        in
        {
          formatter = pkgs.nixfmt-rfc-style;

          pre-commit.settings.hooks.nixfmt-rfc-style.enable = true;

          packages = {
            # Standard names:
            # - `default` for `nix build`
            # - `nannuo-bot` for `nix build .#nannuo-bot`
            default = nannuo-bot;
            nannuo-bot = nannuo-bot;

            nannuo-bot-deps = nannuo-bot-deps;
            update-deps = update-deps;
          };

          # --- Dev Shell ---
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

              echo "[...] Loading Nannuo Bot Dev Environment"
              echo "Java: ${jdk.version}"

              GRADLE_VERSION="${pkgs.gradle_9.version}"
              WRAPPER_PROPS="gradle/wrapper/gradle-wrapper.properties"

              if [ ! -f "$WRAPPER_PROPS" ] || ! grep -q "gradle-$GRADLE_VERSION-bin.zip" "$WRAPPER_PROPS"; then
                echo "[...] Updating Gradle Wrapper to $GRADLE_VERSION"
                gradle wrapper --gradle-version "$GRADLE_VERSION"
              else
                echo "[OK] Gradle Wrapper is up to date ($GRADLE_VERSION)"
              fi
            '';
          };
        };

      flake = {
        nixosConfigurations = {
          # --- Google Cloud Compute flake, currently in production. To be replaced. ---
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

        nixosModules.default = import ./deployments/module.nix self;
      };
    };
}
