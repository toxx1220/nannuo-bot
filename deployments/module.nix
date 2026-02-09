# NixOS module for the Nannuo Bot systemd service.
self:
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

        # Standard hardening
        ProtectSystem = "full"; # Read-only /usr, /boot, /etc
        ProtectHome = true; # Inaccessible /home
        NoNewPrivileges = true; # Cannot escalate to root
        PrivateTmp = true;
      };
    };
  };
}
