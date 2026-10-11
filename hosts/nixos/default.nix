{ pkgs, ... }:

# Acer Nitro V 15 (ANV15-41): Ryzen 5 7535HS + RTX 3050, dual-booting CachyOS's GRUB.
{
  imports = [
    ./hardware-configuration.nix
    ./boot-bridge.nix
    ./drives.nix
    ./drive-script.nix
    ./kali-net.nix
  ];

  networking.hostName = "nixos";

  custom = {
    user.name = "afterlight";
    user.description = "Afterlight";

    desktop = {
      splash.enable = true;
      autologin.enable = true;
    };

    hardware = {
      nvidia.enable = true;
      # 0000:75:00.0 and 0000:01:00.0 in lspci
      nvidia.prime.amdBusId = "PCI:117:0:0";
      nvidia.prime.nvidiaBusId = "PCI:1:0:0";
      laptop = {
        enable = true;
        damx = true;
        linuwuSense = true;
      };
      cachyosKernel.enable = true;
      opentabletdriver.enable = true;
      webhid.enable = true;
    };

    gaming.osu = {
      enable = true;
      wine = true;
    };

    apps.hamachi.enable = true;
  };

  environment.systemPackages = with pkgs; [
    osu-lazer-bin xdotool xprop # ~/.local/bin/osu-lazer uses these
    dotnet-sdk_8 jdk jdt-language-server
    scrcpy ani-cli qemu
  ];

  boot.kernelParams = [
    "usb-storage.quirks=152d:0583:u" # external SSD enclosure misbehaves with UAS
    "amd_pstate=active"
  ];

  # Load the iGPU in the initrd so the boot splash shows at native resolution right away
  boot.initrd.kernelModules = [ "amdgpu" ];

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="cpu", ATTR{cpufreq/energy_performance_preference}="performance"
    # Stable names for the two GPUs; ~/.config/uwsm/env-hyprland picks one at login
    KERNEL=="card*", KERNELS=="0000:01:00.0", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/nvidia-dgpu"
    KERNEL=="card*", KERNELS=="0000:75:00.0", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/amd-igpu"
  '';

  networking.firewall.allowedTCPPorts = [ 32764 ];
  networking.firewall.allowedUDPPorts = [ 32764 7654 ];

  system.stateVersion = "26.05";
}
