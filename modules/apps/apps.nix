{ config, pkgs, lib, ... }:

let
  cfg = config.custom.apps;
in
{
  options.custom.apps = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable desktop applications, media tools, and virtual camera modules";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      brave
      udiskie
      loupe # image viewer
      kdePackages.kate # text editor
      v4l-utils # v4l2 utility tools (e.g., v4l2-ctl)
      xdotool # X11 automation utilities
      xprop
      dotnet-sdk_8
      # Discord with OpenASAR (performance) + Vencord (client mods)
      (discord.override {
        withOpenASAR = true;
        withVencord = true;
      })
    ];

    # OBS Virtual Camera support via v4l2loopback
    boot.extraModulePackages = with config.boot.kernelPackages; [
      v4l2loopback
    ];
    boot.kernelModules = [
      "v4l2loopback"
    ];
    boot.extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=10 card_label="OBS Virtual Camera" exclusive_caps=1
    '';

    # LogMeIn Hamachi VPN service & Haguichi GUI frontend
    services.logmein-hamachi.enable = true;
    programs.haguichi.enable = true;
  };
}
