{ pkgs, ... }:

let
  webhidRules = pkgs.writeTextFile {
    name = "webhid-udev-rules";
    destination = "/etc/udev/rules.d/59-webhid.rules";

    text = ''
      # AE68 Pro — WebHID
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1ca6", ATTRS{idProduct}=="3006", MODE:="0660", GROUP:="users", TAG+="uaccess"

      # SayoDevice K05 HE — WebHID
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="8089", ATTRS{idProduct}=="0009", MODE:="0660", GROUP:="users", TAG+="uaccess"

      # AE68 Pro — WebUSB
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="1ca6", ATTR{idProduct}=="3006", MODE:="0660", GROUP:="users", TAG+="uaccess"

      # SayoDevice K05 HE — WebUSB
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="8089", ATTR{idProduct}=="0009", MODE:="0660", GROUP:="users", TAG+="uaccess"
    '';
  };
in
{
  services.udev.packages = [
    webhidRules
  ];
}
