{ pkgs, ... }:
{
  home.packages = with pkgs; [
    age
    bc
    jq
    nmap
    procs
    speedtest-cli
    ttyper
  ];
}
