{
  projectRootFile = "flake.nix";

  programs.nixfmt.enable = true;
  programs.prettier.enable = true;
  programs.shfmt.enable = true;

  settings.excludes = [
    "settings.json"
    "secrets.yaml"
    ".sops.yaml"
    "*.md"
    "flake.lock"
    "dump.sql"
  ];

  programs.prettier.excludes = [
    "settings.json"
    "secrets.yaml"
    ".sops.yaml"
    "*.md"
    "dump.sql"
  ];
}
