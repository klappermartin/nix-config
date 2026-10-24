{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.oss-references-pruner;
  base = config.programs.oss-references;
in
{
  options.services.oss-references-pruner = {
    enable = lib.mkEnableOption "Weekly launchd agent that runs oss-ref prune";
    minAge = lib.mkOption {
      type = lib.types.str;
      default = "7d";
      description = "Passed as --min-age; orphans younger than this are kept.";
    };
    logDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Library/Logs/oss-references-pruner";
      description = "Where the launchd agent writes stdout/stderr logs.";
    };
    # TODO(linux): expose a systemd.user.timers equivalent when pkgs.stdenv.isLinux
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isDarwin) {
    assertions = [
      {
        assertion = base.enable;
        message = "services.oss-references-pruner.enable requires programs.oss-references.enable = true";
      }
    ];

    home.activation.ossReferencesPrunerLogDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${lib.escapeShellArg cfg.logDir}
    '';

    launchd.agents.oss-references-prune = {
      enable = true;
      config = {
        ProgramArguments = [
          (lib.getExe base.package)
          "prune"
          "--yes"
          "--min-age"
          cfg.minAge
        ];
        EnvironmentVariables = {
          OSS_REFERENCES_ROOT = base.root;
          OSS_REFERENCES_CONSUMER_ROOTS = lib.concatStringsSep ":" base.consumerRoots;
        };
        StartCalendarInterval = [
          {
            Weekday = 1;
            Hour = 9;
            Minute = 0;
          }
        ];
        RunAtLoad = false;
        StandardOutPath = "${cfg.logDir}/stdout.log";
        StandardErrorPath = "${cfg.logDir}/stderr.log";
      };
    };
  };
}
