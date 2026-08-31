{ config, pkgs, lib, ... }:

let
  cfg = config.custom.gaming;

  # Exact osu-lazer launcher with Discord voice bridge, Wayland/PipeWire latency tuning, and GPU offload
  osuLazerScript = pkgs.writeShellScriptBin "osu-lazer" ''
    #!/usr/bin/env bash

    export SDL_VIDEODRIVER=WAYLAND
    export SDL_AUDIODRIVER=pulseaudio
    export PIPEWIRE_LATENCY="256/48000"

    (
        sleep 3
        wid="$(${pkgs.xdotool}/bin/xdotool search --all --class 'osu!' 2>/dev/null | head -n1 || true)"
        [ -n "$wid" ] &&
            ${pkgs.xorg.xprop}/bin/xprop -id "$wid" -f WM_NAME 8s -set WM_NAME 'osu!' 2>/dev/null || true

        # Auto-link osu! audio to Discord voice stream (zero latency overhead)
        for _ in {1..6}; do
            osu_fl="$(${pkgs.pipewire}/bin/pw-link -o 2>/dev/null | grep -iE '(osu|ALSA)' | grep -E '_FL$' | head -n1 || true)"
            osu_fr="$(${pkgs.pipewire}/bin/pw-link -o 2>/dev/null | grep -iE '(osu|ALSA)' | grep -E '_FR$' | head -n1 || true)"
            if [ -n "$osu_fl" ] && [ -n "$osu_fr" ]; then
                ${pkgs.pipewire}/bin/pw-link "$osu_fl" "WEBRTC VoiceEngine:input_FL" 2>/dev/null || true
                ${pkgs.pipewire}/bin/pw-link "$osu_fr" "WEBRTC VoiceEngine:input_FR" 2>/dev/null || true
                break
            fi
            sleep 2
        done
    ) >/dev/null 2>&1 &

    COMMAND=()

    if command -v gamemoderun >/dev/null 2>&1; then
        COMMAND+=(gamemoderun)
    fi

    if command -v prime-run >/dev/null 2>&1; then
        COMMAND+=(prime-run)
    elif command -v nvidia-offload >/dev/null 2>&1; then
        COMMAND+=(nvidia-offload)
    fi

    COMMAND+=("${pkgs.osu-lazer-bin}/bin/osu!")

    exec "''${COMMAND[@]}" "$@"
  '';

  # Exact osu-wine-nixos launcher using steam-run FHS environment, wine-osu, and pipewire pulse server
  osuWineNixosScript = pkgs.writeShellScriptBin "osu-wine-nixos" ''
    #!/usr/bin/env bash
    set -euo pipefail

    AUDIO_FHS="$HOME/.local/share/osuconfig/steam-run-audio"
    WROOT="$HOME/.local/share/osuconfig/wine-osu"
    WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix"
    OSUPATH_FILE="$HOME/.local/share/osuconfig/osupath"

    if [[ -x "$AUDIO_FHS/bin/steam-run" ]]; then
      STEAM_RUN_BIN="$AUDIO_FHS/bin/steam-run"
    elif command -v steam-run >/dev/null 2>&1; then
      STEAM_RUN_BIN="$(command -v steam-run)"
    elif [ -x "${pkgs.steam-run}/bin/steam-run" ]; then
      STEAM_RUN_BIN="${pkgs.steam-run}/bin/steam-run"
    else
      echo "Audio Steam environment (steam-run) is missing."
      exit 1
    fi

    if [[ ! -x "$WROOT/bin/wine" ]]; then
      echo "Normal wine-osu build is missing from $WROOT/bin/wine"
      echo "If you have not set up osu-winello yet, please run the osu-winello setup script."
      exit 1
    fi

    if [[ -r "$OSUPATH_FILE" ]]; then
      OSUPATH="$(<"$OSUPATH_FILE")"
    else
      OSUPATH="/mnt/useless/osu!"
    fi

    "$STEAM_RUN_BIN" env \
      WROOT="$WROOT" \
      WINEPREFIX="$WINEPREFIX" \
      OSUPATH="$OSUPATH" \
      PULSE_SERVER="unix:$XDG_RUNTIME_DIR/pulse/native" \
      WINEDLLOVERRIDES="winemenubuilder.exe=;" \
      bash -c '
        export LD_LIBRARY_PATH="$WROOT/lib/wine/x86_64-unix:''${LD_LIBRARY_PATH:-}"

        cd "$OSUPATH" || exit 1

        "$WROOT/bin/wine" "osu!.exe" "$@"
      ' bash "$@"
  '';

  osuLazerDesktopItem = pkgs.makeDesktopItem {
    name = "osu-lazer";
    desktopName = "osu! (Lazer)";
    comment = "osu! Lazer with Discord audio bridge & low-latency Wayland optimization";
    exec = "osu-lazer %U";
    icon = "osu";
    terminal = false;
    type = "Application";
    categories = [ "Game" ];
    startupWMClass = "osu!";
  };

  osuWineDesktopItem = pkgs.makeDesktopItem {
    name = "osu-wine-nixos";
    desktopName = "osu! (Stable / Wine FHS)";
    comment = "osu! stable running with wine-osu in Steam FHS environment";
    exec = "osu-wine-nixos %U";
    icon = "osu";
    terminal = false;
    type = "Application";
    categories = [ "Game" ];
    startupWMClass = "osu!.exe";
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
        description = "Install osu! Lazer (with Discord audio routing & Wayland low-latency optimization)";
      };

      wine = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install osu! stable Wine tools, Steam-run FHS environment, and osu-wine-nixos";
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
        osuLazerScript
        osuLazerDesktopItem
        pipewire
        xdotool
        xorg.xprop
      ];
    })

    (lib.mkIf (cfg.enable && cfg.osu.enable && cfg.osu.wine) {
      environment.systemPackages = with pkgs; [
        steam-run
        wineWowPackages.staging
        winetricks
        zenity
        wget
        unzip
        cabextract
        libnotify
        xdg-desktop-portal-gtk
        xdotool
        xorg.xprop
        osuWineNixosScript
        osuWineDesktopItem
      ];
    })
  ];
}
