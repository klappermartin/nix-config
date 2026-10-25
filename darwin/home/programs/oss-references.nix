{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.oss-references;
  ossRef = pkgs.writeShellApplication {
    name = "oss-ref";
    runtimeInputs = [
      pkgs.git
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
      pkgs.gnused
    ];
    text = builtins.readFile ./oss-ref.sh;
  };
in
{
  options.programs.oss-references = {
    enable = lib.mkEnableOption "OSS references workflow (oss-ref script + guaranteed root dir + session env var)";
    package = lib.mkOption {
      type = lib.types.package;
      default = ossRef;
      defaultText = lib.literalExpression "oss-ref built from ./oss-ref.sh";
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
