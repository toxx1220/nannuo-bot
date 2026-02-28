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
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
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

      jarSource = import ./jar-source.nix;

      # Single source of truth for versioning
      projectVersion = jarSource.version or "dev-${self.shortRev or "dirty"}";
    in

    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.git-hooks-nix.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

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

          # Fetch the pre-built JAR from GitHub Releases
          jar = pkgs.fetchurl {
            url = jarSource.url;
            hash = jarSource.hash;
          };

          # --- Main Package ---
          # Wraps the pre-built JAR with a headless JDK runtime.
          nannuo-bot = pkgs.stdenv.mkDerivation {
            inherit pname;
            version = projectVersion;

            # No source to unpack — use the pre-built JAR directly
            dontUnpack = true;

            nativeBuildInputs = [ pkgs.makeWrapper ];

            installPhase = ''
              mkdir -p $out/share/java $out/bin
              cp ${jar} $out/share/java/${pname}.jar

              makeWrapper ${jdk_headless}/bin/java $out/bin/${pname} \
                --add-flags "-jar $out/share/java/${pname}.jar"
            '';
          };

          # --- Update JAR Hash Script ---
          update-jar = pkgs.writeShellApplication {
            name = "update-jar";
            runtimeInputs = [
              pkgs.nix
              pkgs.coreutils
              pkgs.git
              pkgs.jq
            ];
            text = builtins.readFile ./scripts/update-jar.sh;
          };

        in
        {
          pre-commit.settings.hooks.nixfmt.enable = true;

          packages = {
            default = nannuo-bot;
            nannuo-bot = nannuo-bot;
            update-jar = update-jar;
          };

          # --- Dev Shell ---
          treefmt.config = import ./treefmt.nix;
          devShells.default = pkgs.mkShell {
            packages = [
              config.treefmt.build.wrapper
              jdk
              pkgs.gradle_9
              pkgs.ktlint
              pkgs.nil
            ];
            shellHook = ''
              # Install the pre-commit hooks
              ${config.pre-commit.installationScript}

              export JAVA_HOME=${jdk}
              # For IDEs to pick up the JDK path easily if needed
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
        nixosModules.default = import ./deployments/module.nix self;
      };
    };
}
