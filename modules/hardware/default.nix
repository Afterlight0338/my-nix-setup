{ ... }:

{
  imports = [
    ./nvidia.nix
    ./amd.nix
    ./intel.nix
    ./bluetooth.nix
    ./pipewire.nix
    ./opentabletdriver.nix
    ./webhid.nix
    ./laptop.nix
    ./cachyos.nix
  ];
}
