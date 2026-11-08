{
  pkgs,
  inputs,
  ...
}:
{
  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
    };

    useGlobalPkgs = true;
    useUserPackages = true;
    backupCommand = "${
      pkgs.writeShellApplication {
        name = "home-manager-backup";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          file=$1
          if [[ -e "$file.backup" || -L "$file.backup" ]]; then
            mv -fT -- "$file.backup" "$file.backup.2"
          fi
          mv -T -- "$file" "$file.backup"
        '';
      }
    }/bin/home-manager-backup";
  };
}
