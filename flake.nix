{
  description = "nannuo bot development and deployment flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    git-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
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
      ...
    }:
    let
      lib = nixpkgs.lib;

      # Source of truth for metadata
      gradleProps = builtins.readFile ./gradle.properties;
      # Helper to extract a value from gradle.properties
      getProp =
        prop:
        lib.removePrefix "${prop}=" (
          lib.findFirst (l: lib.hasPrefix "${prop}=" l) null (lib.splitString "\n" gradleProps)
        );

      javaVersion = getProp "javaVersion";
      pname = getProp "rootProjectName";
      jarSource = import ./jar-source.nix;

      projectVersion = jarSource.version;
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
          jre = pkgs."jdk${javaVersion}_headless";

          # Main Package: Wraps the pre-built JAR
          nannuo-bot =
            pkgs.runCommand pname
              {
                inherit pname;
                version = projectVersion;
                nativeBuildInputs = [ pkgs.makeWrapper ];
              }
              ''
                mkdir -p $out/share/java $out/bin
                cp ${pkgs.fetchurl { inherit (jarSource) url hash; }} $out/share/java/$pname.jar
                makeWrapper ${jre}/bin/java $out/bin/$pname --add-flags "-jar $out/share/java/$pname.jar"
              '';
        in
        {
          pre-commit.settings.hooks.nixfmt.enable = true;

          packages = {
            inherit nannuo-bot;
            default = nannuo-bot;
            update-jar = pkgs.writeShellApplication {
              name = "update-jar";
              runtimeInputs = with pkgs; [
                nix
                coreutils
                git
                jq
              ];
              text = builtins.readFile ./scripts/update-jar.sh;
            };
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
