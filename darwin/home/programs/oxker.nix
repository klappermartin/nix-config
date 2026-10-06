{
  config,
  pkgs,
  oxker-package,
  ...
}:
let
  oxker-colima = pkgs.writeShellApplication {
    name = "oxker";
    text = ''
      for arg in "$@"; do
        case "$arg" in
          --host|--host=*)
            exec ${oxker-package}/bin/oxker "$@"
            ;;
        esac
      done

      exec ${oxker-package}/bin/oxker \
        --host "unix://${config.home.homeDirectory}/.colima/default/docker.sock" \
        "$@"
    '';
  };
in
{
  home.packages = [
    oxker-colima
  ];
}
