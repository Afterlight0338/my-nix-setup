{ config, pkgs, lib, ... }:

let
  cfg = config.custom.hardware.opentabletdriver;
in
{
  options.custom.hardware.opentabletdriver = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable OpenTabletDriver daemon and blacklist conflicting kernel modules";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.opentabletdriver = {
      enable = true;
      daemon.enable = true;
      package = pkgs.opentabletdriver;
      blacklistedKernelModules = [
        "hid-uclogic"
        "wacom"
      ];
    };
  };
}
