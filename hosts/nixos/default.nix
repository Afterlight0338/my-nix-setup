{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./boot-bridge.nix
    ./drives.nix
  ];

  networking.hostName = "nixos";

  # Host specific feature toggles
  custom = {
    user.name = "afterlight";
    user.description = "Afterlight";

    hardware = {
      nvidia.enable = true;
      laptop.enable = true;
      laptop.damx = true;
      laptop.linuwuSense = true;
      cachyosKernel.enable = true;
    };

    system.driveScript.enable = true;
  };

  # Quirks for specific external drive and AMD P-State
  boot.kernelParams = [
    "usb-storage.quirks=152d:0583:u"
    "amd_pstate=active"
  ];

  # CPU Governor policy rule
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="cpu", ATTR{cpufreq/energy_performance_preference}="performance"
    KERNEL=="card*", KERNELS=="0000:01:00.0", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/nvidia-dgpu"
    KERNEL=="card*", KERNELS=="0000:75:00.0", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/amd-igpu"
  '';

  # Open firewall ports for local services
  networking.firewall.allowedTCPPorts = [ 32764 ];
  networking.firewall.allowedUDPPorts = [ 32764 ];
  networking.firewall.enable = true;

  system.stateVersion = "26.05";
}
