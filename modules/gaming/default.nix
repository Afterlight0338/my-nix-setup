{ config, pkgs, lib, ... }:

let
  cfg = config.custom.gaming;
in
{
  options.custom.gaming = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable gaming stack (Steam, GameMode, osu!, ProtonPlus, r2modman)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Steam — open firewall ports for Remote Play, Source servers, and LAN transfers.
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };

    # Feral GameMode daemon
    programs.gamemode.enable = true;

    environment.systemPackages = with pkgs; [
      osu-lazer-bin
      protonplus
      r2modman
      lavat
      cavalier
      tty-clock
    ];
  };
}
