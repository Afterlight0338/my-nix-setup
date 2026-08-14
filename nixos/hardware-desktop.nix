
{ config, pkgs, ... }:

{
nix.settings.experimental-features = [
"nix-command"
"flakes"
];

programs.hyprland = {
enable = true;
xwayland.enable = true;
withUWSM = true;
};

hardware.graphics = {
enable = true;
enable32Bit = true;
};

services.xserver.videoDrivers= [ "nvidia" ];

hardware.nvidia = {
modesetting.enable = true;
open = true;
nvidiaSettings = true;
powerManagement.enable = true;
package = config.boot.kernelPackages.nvidiaPackages.stable;
};

security.polkit.enable = true;
security.rtkit.enable = true;
networking.networkmanager.enable = true;
hardware.bluetooth = {
enable = true;
powerOnBoot = true;
};

services.upower.enable = true;

services.pulseaudio.enable = false;
services.pipewire = {
enable = true;
audio.enable = true;
alsa.enable = true;
alsa.support32Bit = true;
pulse.enable = true;
wireplumber.enable = true;
};

environment.systemPackages = with pkgs; [
kitty
firefox
thunar
git
curl
wget
nano
pciutils
usbutils
mesa-demos
vulkan-tools
wl-clipboard
grim
slurp
brightnessctl
pavucontrol
networkmanagerapplet
nwg-displays
fastfetch
osu-lazer-bin
brave
];


services.udev.extraRules = ''
KERNEL=="card*", KERNELS=="0000:01:00.0", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/nvidia-dgpu"
KERNEL=="card*", KERNELS=="0000:75:00.0", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/amd-igpu"
'';




































}
