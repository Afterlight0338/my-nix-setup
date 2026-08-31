{ config, pkgs, lib, ... }:

let
  cfg = config.custom.hardware.laptop;
in
{
  options.custom.hardware.laptop = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable laptop power management features (upower, etc.)";
    };

    damx = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable ASUS/Acer DAMX laptop management daemon service";
    };

    linuwuSense = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Load linuwu-sense kernel module for Acer laptop sensors";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.upower.enable = true;
    })

    (lib.mkIf cfg.linuwuSense {
      boot.extraModulePackages = [
        (pkgs.linuwu-sense.override {
          linuxPackages = config.boot.kernelPackages;
        })
      ];
      boot.kernelModules = [ "linuwu_sense" ];
    })

    (lib.mkIf cfg.damx {
      environment.systemPackages = [ pkgs.damx-suite ];

      systemd.services.damx-daemon = {
        description = "DAMX Daemon for Acer laptops";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.damx-daemon}/bin/damx-daemon";
          Restart = "on-failure";
          RestartSec = 5;
          User = "root";
        };

        path = with pkgs; [
          sudo
          kmod
          systemd
          coreutils
        ];
      };
    })
  ];
}
