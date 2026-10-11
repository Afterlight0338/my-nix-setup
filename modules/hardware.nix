{ config, lib, pkgs, inputs, ... }:

# GPUs, audio, bluetooth, Acer laptop extras, CachyOS kernel, tablet and keyboard access.
let
  cfg = config.custom.hardware;

  # Let whoever sits at the machine use these devices (uaccess), for flashing tools and
  # web configurators, instead of chmod or world-writable rules. Sorted before 73-seat-late.
  deviceRules = pkgs.writeTextFile {
    name = "device-access-rules";
    destination = "/etc/udev/rules.d/70-device-access.rules";
    text = ''
      # AE68 Pro and SayoDevice K05 HE (WebHID / WebUSB configurators)
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1ca6", ATTRS{idProduct}=="3006", MODE:="0660", GROUP:="users", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="8089", ATTRS{idProduct}=="0009", MODE:="0660", GROUP:="users", TAG+="uaccess"
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="1ca6", ATTR{idProduct}=="3006", MODE:="0660", GROUP:="users", TAG+="uaccess"
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="8089", ATTR{idProduct}=="0009", MODE:="0660", GROUP:="users", TAG+="uaccess"
      # RY5088 keyboards (FUN60, MonsGeek) and their bootloader
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3151", ATTRS{idProduct}=="5030", MODE:="0660", GROUP:="users", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3151", ATTRS{idProduct}=="502a", MODE:="0660", GROUP:="users", TAG+="uaccess"
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="3151", ATTR{idProduct}=="5030", MODE:="0660", GROUP:="users", TAG+="uaccess"
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="3151", ATTR{idProduct}=="502a", MODE:="0660", GROUP:="users", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3151", TAG+="uaccess"
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="3151", TAG+="uaccess"
      # AT32 DFU bootloader (keyboard recovery with dfu-util)
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="2e3c", ATTR{idProduct}=="df11", TAG+="uaccess"
      # Raspberry Pi Pico / RP2040
      SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", TAG+="uaccess"
      SUBSYSTEM=="tty", ATTRS{idVendor}=="2e8a", TAG+="uaccess"
    '';
  };
in
{
  options.custom.hardware = {
    nvidia = {
      enable = lib.mkEnableOption "the NVIDIA driver";
      open = lib.mkEnableOption "NVIDIA's open kernel modules" // { default = true; };
      powerManagement = lib.mkEnableOption "NVIDIA power management" // { default = true; };
      # Hybrid laptops: set both (lspci, written as PCI:bus:device:function in decimal) to let
      # the NVIDIA GPU sleep when unused and get `nvidia-offload <command>`
      prime.amdBusId = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      prime.nvidiaBusId = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
    };
    amdGpu.enable = lib.mkEnableOption "the AMD GPU driver";
    intelGpu.enable = lib.mkEnableOption "Intel GPU video acceleration";
    audio.enable = lib.mkEnableOption "PipeWire audio" // { default = true; };
    bluetooth.enable = lib.mkEnableOption "Bluetooth" // { default = true; };
    laptop = {
      enable = lib.mkEnableOption "battery reporting (upower)";
      damx = lib.mkEnableOption "the DAMX fan and performance daemon (Acer)";
      linuwuSense = lib.mkEnableOption "the linuwu-sense sensor module (Acer)";
    };
    cachyosKernel.enable = lib.mkEnableOption "the CachyOS kernel (BORE scheduler, prebuilt)";
    opentabletdriver.enable = lib.mkEnableOption "OpenTabletDriver";
    webhid.enable = lib.mkEnableOption "access to custom keyboards, keypads and microcontrollers";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.nvidia.enable {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [ nvidia-vaapi-driver libva-vdpau-driver libvdpau-va-gl ];
      };
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        modesetting.enable = true;
        open = cfg.nvidia.open;
        nvidiaSettings = true;
        powerManagement.enable = cfg.nvidia.powerManagement;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };
    })

    (lib.mkIf (cfg.nvidia.enable && cfg.nvidia.prime.nvidiaBusId != null) {
      hardware.nvidia.prime = {
        offload.enable = true;
        offload.enableOffloadCmd = true;
        amdgpuBusId = cfg.nvidia.prime.amdBusId;
        nvidiaBusId = cfg.nvidia.prime.nvidiaBusId;
      };
      hardware.nvidia.powerManagement.finegrained = true;
    })

    (lib.mkIf cfg.amdGpu.enable {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };
      services.xserver.videoDrivers = [ "amdgpu" ];
    })

    (lib.mkIf cfg.intelGpu.enable {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [ intel-media-driver intel-vaapi-driver ];
      };
    })

    (lib.mkIf cfg.audio.enable {
      services.pulseaudio.enable = false;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
      };
    })

    (lib.mkIf cfg.bluetooth.enable {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
    })

    (lib.mkIf cfg.laptop.enable {
      services.upower.enable = true;
    })

    (lib.mkIf cfg.laptop.linuwuSense {
      boot.extraModulePackages = [
        (pkgs.linuwu-sense.override { linuxPackages = config.boot.kernelPackages; })
      ];
      boot.kernelModules = [ "linuwu_sense" ];
    })

    (lib.mkIf cfg.laptop.damx {
      environment.systemPackages = [ pkgs.damx-suite ];
      systemd.services.damx-daemon = {
        description = "DAMX daemon for Acer laptops";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        path = with pkgs; [ sudo kmod systemd coreutils ];
        serviceConfig = {
          ExecStart = "${pkgs.damx-daemon}/bin/damx-daemon";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    })

    (lib.mkIf cfg.cachyosKernel.enable {
      nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];
      boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-x86_64-v3;
      # Prebuilt kernels, so nothing gets compiled
      nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
      nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
    })

    (lib.mkIf cfg.opentabletdriver.enable {
      hardware.opentabletdriver = {
        enable = true;
        daemon.enable = true;
        # These grab the tablet before OpenTabletDriver can
        blacklistedKernelModules = [ "hid-uclogic" "wacom" ];
      };
    })

    (lib.mkIf cfg.webhid.enable {
      services.udev.packages = [ deviceRules ];
    })
  ];
}
