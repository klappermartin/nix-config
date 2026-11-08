{ pkgs, ... }:
{
  home.packages = with pkgs; [
    discord
    discordo
    mqttui
    mutt
    slack
    telegram-desktop
    thunderbird
    whatsapp-for-mac
  ];
}
