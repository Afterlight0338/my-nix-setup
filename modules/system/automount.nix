{ config, pkgs, lib, ... }:

let
  cfg = config.custom.system.automount;
in
{
  options.custom.system.automount = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable removable-drive automount backend and desktop integration";
    };
  };

  config = lib.mkIf cfg.enable {
    services.udisks2.enable = true;
    services.gvfs.enable = true;
    environment.systemPackages = with pkgs; [
      udiskie
    ];
  };
}
