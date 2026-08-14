{ pkgs, ... }:

{
  # Storage discovery and mounting for Dolphin and other file managers.
  services.udisks2.enable = true;

  # GTK file-manager support, MTP phones, trash and remote locations.
  services.gvfs.enable = true;

  programs.dconf.enable = true;

  # Qt platform theme — uses the caelestia.colors KDE colour scheme already
  # configured in ~/.config/qtengine/. QT_QPA_PLATFORMTHEME=qtengine is set by
  # hyprland/env.lua; we only need the plugin and a widget style on the path.
  environment.systemPackages = with pkgs; [
    kdePackages.dolphin
    kdePackages.kio
    kdePackages.kio-extras
    kdePackages.kio-fuse
    kdePackages.qtsvg

    qtengine            # platform theme plugin (reads ~/.config/qtengine/config.json)
    kdePackages.breeze  # Qt6 widget style for Caelestia KDE colour scheme

    papirus-icon-theme
    gnome-themes-extra
  ];
}

