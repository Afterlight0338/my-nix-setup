{ config, pkgs, lib, ... }:

let
  cfg = config.custom.desktop.fileManager;
in
{
  options.custom.desktop.fileManager = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Dolphin / Thunar file managers and desktop integration services";
    };
  };

  config = lib.mkIf cfg.enable {
    # Storage discovery and mounting for Dolphin and other file managers.
    services.udisks2.enable = true;

    # GTK file-manager support, MTP phones, trash and remote locations.
    services.gvfs.enable = true;

    programs.dconf.enable = true;

    # Thumbnailer service for video/image previews in Dolphin & Thunar
    services.tumbler.enable = true;

    # Qt platform theme — uses the caelestia.colors KDE colour scheme already
    # configured in ~/.config/qtengine/.
    environment.systemPackages = with pkgs; [
      kdePackages.dolphin
      kdePackages.kio
      kdePackages.kio-extras
      kdePackages.kio-fuse
      kdePackages.kio-admin     # Allows "Open as Root/Admin" in Dolphin
      kdePackages.ffmpegthumbs  # Video thumbnail generator for Dolphin
      kdePackages.ark           # Archive manager & context menu extraction
      kdePackages.kservice
      kdePackages.kde-cli-tools
      kdePackages.qtsvg
      shared-mime-info
      p7zip
      unrar

      qtengine            # platform theme plugin (reads ~/.config/qtengine/config.json)
      kdePackages.breeze  # Qt6 widget style for Caelestia KDE colour scheme

      papirus-icon-theme
      gnome-themes-extra
      thunar
    ];
  };
}
