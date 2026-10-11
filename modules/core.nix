{ config, lib, pkgs, ... }:

# Base system: user, locale, Nix, networking, shell, polkit, and the bits Fedora/Ubuntu
# do out of the box that NixOS doesn't (running downloaded binaries and AppImages).
let
  cfg = config.custom;

  # nixpkgs' library set for AppImages / Electron apps (gtk3, libgbm, expat, nss, SDL2, ...)
  appimageArgs = pkgs.appimageTools.defaultFhsEnvArgs;
in
{
  options.custom = {
    user.name = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
    };
    user.description = lib.mkOption {
      type = lib.types.str;
      default = "NixOS User";
    };
    locale = {
      timeZone = lib.mkOption {
        type = lib.types.str;
        default = "Asia/Kuala_Lumpur";
      };
      defaultLocale = lib.mkOption {
        type = lib.types.str;
        default = "en_US.UTF-8";
      };
      # Dates, units, paper size and so on
      extraLocale = lib.mkOption {
        type = lib.types.str;
        default = "en_SG.UTF-8";
      };
    };
    system.smartGc.enable = lib.mkEnableOption "weekly cleanup that keeps the last 3 generations" // {
      default = true;
    };
  };

  config = lib.mkMerge [
    {
      nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
        auto-optimise-store = true;
        trusted-users = [ "root" "@wheel" ];
      };
      nixpkgs.config.allowUnfree = true;

      networking.networkmanager.enable = true;

      time.timeZone = cfg.locale.timeZone;
      i18n.defaultLocale = cfg.locale.defaultLocale;
      i18n.extraLocaleSettings = lib.genAttrs [
        "LC_ADDRESS" "LC_IDENTIFICATION" "LC_MEASUREMENT" "LC_MONETARY" "LC_NAME"
        "LC_NUMERIC" "LC_PAPER" "LC_TELEPHONE" "LC_TIME"
      ] (_: cfg.locale.extraLocale);

      users.users.${cfg.user.name} = {
        isNormalUser = true;
        description = cfg.user.description;
        extraGroups = [ "networkmanager" "wheel" "video" ];
        shell = pkgs.zsh;
      };

      programs.zsh = {
        enable = true;
        ohMyZsh = {
          enable = true;
          theme = "";
          plugins = [ "git" ];
        };
      };

      security.polkit.enable = true;
      security.rtkit.enable = true;
      systemd.user.services.polkit-gnome-authentication-agent-1 = {
        description = "polkit-gnome-authentication-agent-1";
        wantedBy = [ "graphical-session.target" ];
        wants = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };

      # Keyring for browsers, Discord, git, VS Code
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.hyprland.enableGnomeKeyring = true;

      # Downloaded binaries, Electron apps and AppImages expect a normal Linux library layout
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          stdenv.cc.cc zlib glib icu openssl libxml2 fuse3 libsecret dbus cups libusb1 nspr nss
          fontconfig freetype pango cairo atk gdk-pixbuf
          libx11 libxcursor libxinerama libxext libxrandr libxi libxfixes libxrender libxcb
          libxcomposite libxdamage libxshmfence libxkbcommon wayland libGL vulkan-loader
          alsa-lib libpulseaudio
        ] ++ (appimageArgs.targetPkgs pkgs) ++ (appimageArgs.multiPkgs pkgs);
      };

      # ./thing.AppImage just runs. ICU is for .NET apps (osu!lazer AppImage).
      programs.appimage = {
        enable = true;
        binfmt = true;
        package = pkgs.appimage-run.override { extraPkgs = p: [ p.icu ]; };
      };

      # Not tmpfs: Nix builds in /tmp and could fill RAM
      boot.tmp.cleanOnBoot = true;

      environment.systemPackages = with pkgs; [
        git curl wget nano unzip file lsof
        psmisc # killall, which Caelestia's theme switching needs
        pciutils usbutils mesa-demos vulkan-tools
        xdg-user-dirs xdg-utils
        polkit_gnome
        comma # , <command> runs anything from nixpkgs once
        uv # Python projects; its own downloaded Pythons run via nix-ld
      ];

      # flake nixpkgs has no programs.sqlite, so the stock "command not found" hint is off; nix-index reads the same DB
      programs.nix-index.enable = true;
      # Nix-built Pythons fail on pip wheels (libstdc++.so.6), so uv only uses its own
      environment.variables.UV_PYTHON_PREFERENCE = "only-managed";

      # comma needs a nix-index database; fetch the prebuilt one weekly instead of indexing locally
      systemd.user.services.nix-index-database = {
        description = "Download prebuilt nix-index database for comma";
        path = [ pkgs.curl pkgs.coreutils ];
        script = ''
          dir="$HOME/.cache/nix-index"
          mkdir -p "$dir"
          curl -fsSL -o "$dir/files.tmp" https://github.com/nix-community/nix-index-database/releases/latest/download/index-x86_64-linux
          mv "$dir/files.tmp" "$dir/files"
        '';
        serviceConfig.Type = "oneshot";
      };
      systemd.user.timers.nix-index-database = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
      };
    }

    # Keep the current and 2 previous generations no matter how old; delete older ones after 14 days
    (lib.mkIf cfg.system.smartGc.enable {
      systemd.services.nixos-smart-gc = {
        description = "Delete old NixOS generations, keep the last 3";
        path = with pkgs; [ coreutils gnused nix ];
        serviceConfig.Type = "oneshot";
        script = ''
          cutoff=$(( $(date +%s) - 14 * 86400 ))
          links=( $(ls -d /nix/var/nix/profiles/system-*-link | sort -V) )
          (( ''${#links[@]} > 3 )) || links=( x x x ) # nothing older than the last 3
          old=()
          for link in "''${links[@]:0:''${#links[@]}-3}"; do
            (( $(stat -c %Y "$link") < cutoff )) && old+=( "$(basename "$link" | sed -E 's/system-([0-9]+)-link/\1/')" )
          done
          (( ''${#old[@]} )) && nix-env -p /nix/var/nix/profiles/system --delete-generations "''${old[@]}"
          nix-collect-garbage
          nix-store --optimise
        '';
      };
      systemd.timers.nixos-smart-gc = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
        };
      };
    })
  ];
}
