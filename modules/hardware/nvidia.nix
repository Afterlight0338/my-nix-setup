{ config, pkgs, lib, ... }:

let
  cfg = config.custom.hardware.nvidia;
in
{
  options.custom.hardware.nvidia = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable NVIDIA proprietary graphics drivers and hardware acceleration";
    };

    open = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use the open-source NVIDIA kernel modules";
    };

    powerManagement = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable NVIDIA power management";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      modesetting.enable = true;
      open = cfg.open;
      nvidiaSettings = true;
      powerManagement.enable = cfg.powerManagement;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
}
