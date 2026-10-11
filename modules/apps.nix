{ config, lib, pkgs, ... }:

# Everyday desktop apps, Flatpak, OBS virtual camera, Hamachi.
let
  cfg = config.custom.apps;
in
{
  options.custom.apps = {
    enable = lib.mkEnableOption "the desktop apps" // { default = true; };
    flatpak.enable = lib.mkEnableOption "Flatpak" // { default = true; };
    obsVirtualCam.enable = lib.mkEnableOption "the OBS virtual camera" // { default = true; };
    hamachi.enable = lib.mkEnableOption "LogMeIn Hamachi and the Haguichi frontend";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      environment.systemPackages = with pkgs; [
        brave
        (discord.override {
          withOpenASAR = true; # faster startup
          withVencord = true;
        })
        whatsapp-electron
        loupe kdePackages.kate
        mpv vlc yt-dlp easyeffects
        qbittorrent gparted ntfs3g
        tty-clock lavat cavalier
      ];
    }

    (lib.mkIf cfg.flatpak.enable {
      services.flatpak.enable = true;
    })

    (lib.mkIf cfg.obsVirtualCam.enable {
      boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
      boot.kernelModules = [ "v4l2loopback" ];
      boot.extraModprobeConfig = ''
        options v4l2loopback devices=1 video_nr=10 card_label="OBS Virtual Camera" exclusive_caps=1
      '';
      environment.systemPackages = [ pkgs.v4l-utils ];
    })

    (lib.mkIf cfg.hamachi.enable {
      services.logmein-hamachi.enable = true;
      programs.haguichi.enable = true;
    })
  ]);
}
