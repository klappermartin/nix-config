{
  config,
  pkgs,
  ...
}:
let
  oxker-colima = pkgs.writeShellApplication {
    name = "oxker";
    text = ''
      for arg in "$@"; do
        case "$arg" in
          --host|--host=*)
            exec ${pkgs.oxker}/bin/oxker "$@"
            ;;
        esac
      done

      exec ${pkgs.oxker}/bin/oxker \
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
