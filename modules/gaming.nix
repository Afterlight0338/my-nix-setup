{ config, lib, pkgs, ... }:

# Steam, GameMode and osu! (lazer with a Discord audio bridge, stable through wine-osu).
let
  cfg = config.custom.gaming;

  osuLazerScript = pkgs.writeShellScriptBin "osu-lazer" ''
    #!/usr/bin/env bash

    export SDL_VIDEODRIVER=WAYLAND
    export SDL_AUDIODRIVER=pulseaudio
    export PIPEWIRE_LATENCY="256/48000"

    (
        sleep 3
        wid="$(${pkgs.xdotool}/bin/xdotool search --all --class 'osu!' 2>/dev/null | head -n1 || true)"
        [ -n "$wid" ] &&
            ${pkgs.xprop}/bin/xprop -id "$wid" -f WM_NAME 8s -set WM_NAME 'osu!' 2>/dev/null || true

        # Link osu! audio into Discord's voice input so calls hear the game
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
    enable = lib.mkEnableOption "Steam, GameMode and mod managers" // { default = true; };
    osu = {
      enable = lib.mkEnableOption "osu!";
      # Launcher that routes osu! audio into Discord calls and runs it on the dGPU
      lazer = lib.mkEnableOption "osu!lazer" // { default = true; };
      # osu! stable through wine-osu inside steam-run (set up with osu-winello first)
      wine = lib.mkEnableOption "osu! stable via wine-osu";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Firewall ports for Remote Play, game servers and LAN transfers
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
      };

      programs.gamemode.enable = true;

      environment.systemPackages = with pkgs; [
        protonplus
        r2modman
      ];
    })

    (lib.mkIf (cfg.enable && cfg.osu.enable && cfg.osu.lazer) {
      environment.systemPackages = with pkgs; [
        osu-lazer-bin
        osuLazerScript
        osuLazerDesktopItem
        pipewire
        xdotool
        xprop
      ];
    })

    (lib.mkIf (cfg.enable && cfg.osu.enable && cfg.osu.wine) {
      environment.systemPackages = with pkgs; [
        steam-run
        zenity
        wget
        unzip
        cabextract
        libnotify
        xdg-desktop-portal-gtk
        xdotool
        xprop
        osuWineNixosScript
        osuWineDesktopItem
      ];
    })
  ];
}
