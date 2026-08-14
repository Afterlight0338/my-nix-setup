{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    brave
    udiskie

    # GNOME companion apps — used for file-opening delegates
    loupe              # image viewer
    kdePackages.kate   # text editor

    # XDG desktop portal for Wayland (needed for xdg-open under Hyprland)
    xdg-desktop-portal-gnome
  ];
}
