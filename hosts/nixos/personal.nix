{ ... }:

# Everything about my setup that isn't tied to the Acer laptop's hardware. hosts/nixos pulls
# this in with the laptop bits, and `./setup` (afterlight mode) pulls it into other machines.
{
  imports = [
    ./drives.nix
    ./drive-script.nix
    ./kali-net.nix
  ];

  custom = {
    user.name = "afterlight";
    user.description = "Afterlight";

    desktop = {
      splash.enable = true;
      autologin.enable = true;
    };

    hardware = {
      cachyosKernel.enable = true;
      opentabletdriver.enable = true;
      webhid.enable = true;
    };

    gaming.osu = {
      enable = true;
      wine = true;
    };

    apps.hamachi.enable = true;
    apps.devTools.enable = true;
  };

  boot.kernelParams = [
    "usb-storage.quirks=152d:0583:u" # external SSD enclosure misbehaves with UAS
  ];

  networking.firewall.allowedTCPPorts = [ 32764 ];
  networking.firewall.allowedUDPPorts = [ 32764 7654 ];
}
