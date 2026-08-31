{ config, pkgs, lib, ... }:

let
  cfg = config.custom.apps;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.whatsapp-custom
    ];
  };
}
