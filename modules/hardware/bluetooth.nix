{ config, lib, ... }:

let
  cfg = config.custom.hardware.bluetooth;
in
{
  options.custom.hardware.bluetooth = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Bluetooth service";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
