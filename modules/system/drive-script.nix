{ config, pkgs, lib, ... }:

let
  cfg = config.custom.system.driveScript;

  driveScript = pkgs.writeShellScriptBin "drive" ''
    #!/usr/bin/env bash
    set -euo pipefail

    DEVICE="/dev/disk/by-uuid/5E6AF7106AF6E3A5"
    MOUNTPOINT="/mnt/useless"

    resolve_dev() {
      readlink -f "$DEVICE"
    }

    usage() {
      echo "Usage: drive {mount|umount|fix|status|remount}"
      echo ""
      echo "  mount     Mount the drive at $MOUNTPOINT"
      echo "  umount    Cleanly unmount the drive"
      echo "  fix       Clear NTFS dirty flag (ntfsfix -d) - unmounts first if needed"
      echo "  status    Show mount state, dirty flag, and recent dmesg for the drive"
      echo "  remount   fix + mount in one step"
      exit 1
    }

    [ $# -eq 0 ] && usage

    case "$1" in
      mount)
        if mount | grep -q "$MOUNTPOINT"; then
          echo "Already mounted at $MOUNTPOINT"
        else
          sudo mount "$MOUNTPOINT"
          echo "Mounted at $MOUNTPOINT"
        fi
        ;;

      umount)
        if mount | grep -q "$MOUNTPOINT"; then
          sudo umount "$MOUNTPOINT"
          echo "Unmounted $MOUNTPOINT"
        else
          echo "Not mounted"
        fi
        ;;

      fix)
        if mount | grep -q "$MOUNTPOINT"; then
          echo "Unmounting first..."
          sudo umount "$MOUNTPOINT"
        fi
        REALDEV=$(resolve_dev)
        echo "Running ntfsfix -d on $REALDEV..."
        sudo ntfsfix -d "$REALDEV"
        ;;

      status)
        REALDEV=$(resolve_dev)
        echo "Device: $REALDEV"
        echo ""
        if mount | grep -q "$MOUNTPOINT"; then
          echo "Mount:  mounted at $MOUNTPOINT"
        else
          echo "Mount:  not mounted"
        fi
        echo ""
        echo "Recent dmesg for this device:"
        sudo dmesg | grep -iE 'sda|ntfs3|uas|DID_NO_CONNECT' | tail -10
        ;;

      remount)
        "$0" fix
        "$0" mount
        ;;

      *)
        usage
        ;;
    esac
  '';
in
{
  options.custom.system.driveScript = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install the custom 'drive' mount helper script";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ driveScript ];
  };
}
