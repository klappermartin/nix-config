{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.oss-references;
  ossRefSources = import ./oss-ref/sources.nix;
  ossRef = pkgs.writeShellApplication {
    name = "oss-ref";
    runtimeInputs = [
      pkgs.git
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
      pkgs.gnused
      pkgs.jq
    ];
    # Keep the installed command self-contained while keeping its source split
    # into focused, independently reviewable Bash modules.
    text = builtins.concatStringsSep "\n\n" (map builtins.readFile ossRefSources);
  };
in
{
  options.programs.oss-references = {
    enable = lib.mkEnableOption "OSS references workflow (oss-ref script + guaranteed root dir + session env var)";
    package = lib.mkOption {
      type = lib.types.package;
      default = ossRef;
      defaultText = lib.literalExpression "oss-ref assembled from ./oss-ref/ modules";
      description = "The oss-ref package.";
    };
    root = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/code/others/oss-references";
      description = "Absolute path to the OSS references root. Guaranteed to exist on activation.";
    };
    consumerRoots = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "${config.home.homeDirectory}/code" ];
      description = "Existing roots scanned for consumer symlinks. add requires a discoverable destination in this scope; prune aborts on missing roots or scan errors. Exported colon-joined.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.sessionVariables = {
      OSS_REFERENCES_ROOT = cfg.root;
      OSS_REFERENCES_CONSUMER_ROOTS = lib.concatStringsSep ":" cfg.consumerRoots;
    };
    home.activation.ossReferencesRoot = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${lib.escapeShellArg cfg.root}
    '';
  };
}
