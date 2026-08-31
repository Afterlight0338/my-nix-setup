{ config, pkgs, lib, ... }:

let
  cfg = config.custom.gaming;

  osuWineLauncher = pkgs.writeShellScriptBin "osu-wine" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Low-latency audio & Wine optimizations for osu! stable
    export PIPEWIRE_LATENCY="128/48000"
    export STAGING_AUDIO_DURATION="10000"
    export WINEFSYNC=1
    export WINEESYNC=1
    export DXVK_HUD=0

    # Auto-rename window to 'osu!' for Discord RPC / window matchers
    (
      sleep 3
      wid="$(xdotool search --all --class 'osu!' 2>/dev/null | head -n1 || true)"
      [ -n "$wid" ] && xprop -id "$wid" -f WM_NAME 8s -set WM_NAME 'osu!' 2>/dev/null || true
    ) >/dev/null 2>&1 &

    OSU_DIR="$HOME/.local/share/osu-winello/osu"
    OSU_EXE="$OSU_DIR/osu!.exe"

    if [ -f "$OSU_EXE" ]; then
      if command -v prime-run >/dev/null 2>&1; then
        exec prime-run wine "$OSU_EXE" "$@"
      elif command -v nvidia-offload >/dev/null 2>&1; then
        exec nvidia-offload wine "$OSU_EXE" "$@"
      else
        exec wine "$OSU_EXE" "$@"
      fi
    else
      echo "osu! stable not found in $OSU_DIR."
      echo "Would you like to download and run the osu-winello installer now?"
      read -rp "Run installer? [Y/n]: " ans
      if [[ "${ans:-y}" =~ ^[yY] ]]; then
        INSTALL_DIR="$(mktemp -d)"
        git clone https://github.com/NelloKudo/osu-winello.git "$INSTALL_DIR"
        chmod +x "$INSTALL_DIR/osu-winello.sh"
        bash "$INSTALL_DIR/osu-winello.sh"
      else
        exit 1
      fi
    fi
  '';

  osuWineDesktopItem = pkgs.makeDesktopItem {
    name = "osu-wine";
    desktopName = "osu! (Stable / Wine)";
    comment = "osu! stable running with Wine and PipeWire low-latency audio";
    exec = "osu-wine %U";
    icon = "osu";
    terminal = false;
    type = "Application";
    categories = [ "Game" ];
  };
in
{
  options.custom.gaming = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable gaming stack (Steam, GameMode, ProtonPlus, r2modman)";
    };

    osu = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable osu! rhythm game suite";
      };

      lazer = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install osu! Lazer (native Wayland binary release)";
      };

      wine = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install osu! stable Wine tools, low-latency audio patches & osu-winello helper";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Steam — open firewall ports for Remote Play, Source servers, and LAN transfers.
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
      };

      # Feral GameMode daemon
      programs.gamemode.enable = true;

      environment.systemPackages = with pkgs; [
        protonplus
        r2modman
        lavat
        cavalier
        tty-clock
      ];
    })

    (lib.mkIf (cfg.enable && cfg.osu.enable && cfg.osu.lazer) {
      environment.systemPackages = with pkgs; [
        osu-lazer-bin
      ];
    })

    (lib.mkIf (cfg.enable && cfg.osu.enable && cfg.osu.wine) {
      environment.systemPackages = with pkgs; [
        wineWowPackages.staging
        winetricks
        zenity
        wget
        unzip
        cabextract
        libnotify
        xdg-desktop-portal-gtk
        xdotool
        xprop
        osuWineLauncher
        osuWineDesktopItem
      ];
    })
  ];
}
