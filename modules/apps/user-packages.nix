{ config, pkgs, lib, ... }:

let
  cfg = config.custom.apps;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mpv
      yt-dlp
      scrcpy
      unzip
      qbittorrent
      vlc
      gparted
      easyeffects
      wl-gammactl
      hyprsunset
      ntfs3g
      btop
      appimage-run
      ripgrep
      comma # Run any Nix package on the fly with ", <command>"
      xdg-utils # Standard xdg-open / desktop integration
      whatsapp-electron
    ];
  };
}
