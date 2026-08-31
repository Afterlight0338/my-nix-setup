{ ... }:

{
  # External SATA SSD
  fileSystems."/mnt/useless" = {
    device = "/dev/disk/by-uuid/5E6AF7106AF6E3A5";
    fsType = "ntfs3";
    options = [
      "rw"
      "uid=1000"
      "gid=100"
      "umask=022"
      "nofail"
      "x-systemd.device-timeout=5s"
      "x-gvfs-show"
      "x-gvfs-name=Useless"
    ];
  };

  # Windows/data partition
  fileSystems."/mnt/useful" = {
    device = "/dev/disk/by-uuid/C62C66AE2C6698E7";
    fsType = "ntfs3";
    options = [
      "rw"
      "uid=1000"
      "gid=100"
      "umask=022"
      "nofail"
      "x-systemd.device-timeout=5s"
      "x-gvfs-show"
      "x-gvfs-name=Useful"
    ];
  };

  # CachyOS/Linux Btrfs partition
  fileSystems."/mnt/linux-nvme0" = {
    device = "/dev/disk/by-uuid/e738c6a3-e33d-42f1-8d88-197204bbc442";
    fsType = "btrfs";
    options = [
      "rw"
      "subvolid=5"
      "nofail"
      "x-systemd.device-timeout=5s"
      "x-gvfs-show"
      "x-gvfs-name=Linux-NVMe0"
    ];
  };

  # Other Btrfs partition
  fileSystems."/mnt/linux-nvme1" = {
    device = "/dev/disk/by-uuid/03366a40-50f3-4b1d-b5f6-1f53f6d0efb1";
    fsType = "btrfs";
    options = [
      "rw"
      "subvolid=5"
      "nofail"
      "x-systemd.device-timeout=5s"
      "x-gvfs-show"
      "x-gvfs-name=Linux-NVMe1"
    ];
  };

  # Other NTFS partition
  fileSystems."/mnt/ntfs-nvme1" = {
    device = "/dev/disk/by-uuid/5650691E506905D9";
    fsType = "ntfs3";
    options = [
      "rw"
      "uid=1000"
      "gid=100"
      "umask=022"
      "nofail"
      "x-systemd.device-timeout=5s"
      "x-gvfs-show"
      "x-gvfs-name=NTFS-NVMe1"
    ];
  };
}
