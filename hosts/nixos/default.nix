{ ... }:

# Acer Nitro V 15 (ANV15-41): Ryzen 5 7535HS + RTX 3050, dual-booting CachyOS's GRUB.
# The rest of my setup lives in personal.nix.
{
  imports = [
    ./hardware-configuration.nix
    ./boot-bridge.nix
    ./personal.nix
  ];

  networking.hostName = "nixos";

  custom.hardware = {
    nvidia.enable = true;
    # 0000:75:00.0 and 0000:01:00.0 in lspci
    nvidia.prime.amdBusId = "PCI:117:0:0";
    nvidia.prime.nvidiaBusId = "PCI:1:0:0";
    laptop = {
      enable = true;
      damx = true;
      linuwuSense = true;
    };
  };

  boot.kernelParams = [ "amd_pstate=active" ];

  # Load the iGPU in the initrd so the boot splash shows at native resolution right away
  boot.initrd.kernelModules = [ "amdgpu" ];

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="cpu", ATTR{cpufreq/energy_performance_preference}="performance"
    # Stable names for the two GPUs; ~/.config/uwsm/env-hyprland picks one at login
    KERNEL=="card*", KERNELS=="0000:01:00.0", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/nvidia-dgpu"
    KERNEL=="card*", KERNELS=="0000:75:00.0", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/amd-igpu"
  '';

  system.stateVersion = "26.05";
}
