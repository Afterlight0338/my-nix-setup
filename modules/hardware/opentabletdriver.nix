{ config, pkgs, lib, ... }:

let
  cfg = config.custom.hardware.opentabletdriver;
in
{
  options.custom.hardware.opentabletdriver = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable OpenTabletDriver daemon and blacklist conflicting kernel modules";
    };

    preconfigure = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Pre-configure tuned tablet active area (67.67x39.39mm @ 180° rotation) and low-latency smoothing filters";
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
