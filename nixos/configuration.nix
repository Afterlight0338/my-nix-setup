# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, ... }:

let
  damxFlake = builtins.getFlake "path:/etc/nixos/damx-flake";

  # Build linuwu-sense against the currently configured kernel.
  linuwuSense =
    damxFlake.packages.${pkgs.stdenv.hostPlatform.system}."linuwu-sense".override {
      linuxPackages = config.boot.kernelPackages;
    };
in

{
  imports = [
    # Hardware scan results (auto-generated — do not edit manually).
    ./hardware-configuration.nix
    # Boot loader & GRUB configuration.
    ./boot-bridge.nix
    # GPU / display hardware settings.
    ./hardware-desktop.nix
    # Caelestia desktop theme.
    ./caelestia-theme.nix
    # WebHID udev rules (for tablet / peripheral access).
    ./webhid.nix
    # Filesystem mount points.
    ./drives.nix
    # Desktop application configuration.
    ./desktop-apps.nix
    # Removable-drive auto-mount rules.
    ./automount.nix
    # Shell environment (aliases, variables, etc.).
    ./shell.nix
    # File manager settings.
    ./file-manager.nix
    # Helper script for drive management.
    ./drive-script.nix
    # User-specific package list.
    ./user-packages.nix
    # ASUS DAMX laptop-control service (from local flake).
    damxFlake.nixosModules.damx
  ];

  # ---------------------------------------------------------------------------
  # Kernel
  # ---------------------------------------------------------------------------

  # Track the latest stable kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Load the ASUS sensor kernel module.
  boot.extraModulePackages = [ linuwuSense ];
  boot.kernelModules = [ "linuwu_sense" ];

  # Apply a patch that raises the USB transfer-size limit.
  boot.kernelPatches = [
    {
      name = "usb-big-transfers";
      patch = ./usb-big-transfers.patch;
    }
  ];

  # Work around quirks on the external drive with USB ID 152d:0583.
  boot.kernelParams = [
  "usb-storage.quirks=152d:0583:u"
  "amd_pstate=active"
  ];

  services.udev.extraRules = ''
  ACTION=="add", SUBSYSTEM=="cpu", ATTR{cpufreq/energy_performance_preference}="performance"
  '';

  # ---------------------------------------------------------------------------
  # Networking
  # ---------------------------------------------------------------------------

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # ---------------------------------------------------------------------------
  # Locale & time
  # ---------------------------------------------------------------------------

  time.timeZone = "Asia/Kuala_Lumpur";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "en_SG.UTF-8";
    LC_IDENTIFICATION = "en_SG.UTF-8";
    LC_MEASUREMENT    = "en_SG.UTF-8";
    LC_MONETARY       = "en_SG.UTF-8";
    LC_NAME           = "en_SG.UTF-8";
    LC_NUMERIC        = "en_SG.UTF-8";
    LC_PAPER          = "en_SG.UTF-8";
    LC_TELEPHONE      = "en_SG.UTF-8";
    LC_TIME           = "en_SG.UTF-8";
  };

  # ---------------------------------------------------------------------------
  # Hardware peripherals
  # ---------------------------------------------------------------------------

  # OpenTabletDriver — blacklist the conflicting kernel drivers so OTD has
  # exclusive access to the tablet.
  hardware.opentabletdriver.enable = true;
  hardware.opentabletdriver.daemon.enable = true;
  hardware.opentabletdriver.package = pkgs.opentabletdriver;
  hardware.opentabletdriver.blacklistedKernelModules = [
    "hid-uclogic"
    "wacom"
  ];

  # ---------------------------------------------------------------------------
  # Display / input
  # ---------------------------------------------------------------------------

  # X11 keyboard layout (used even under Wayland for some tools).
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # ---------------------------------------------------------------------------
  # Users
  # ---------------------------------------------------------------------------

  users.users."afterlight" = {
    isNormalUser = true;
    description  = "Afterlight";
    # wheel — sudo access; networkmanager — manage network connections.
    extraGroups  = [ "networkmanager" "wheel" ];
  };

  # ---------------------------------------------------------------------------
  # Packages
  # ---------------------------------------------------------------------------

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # osu! (stable Lazer binary release)
    osu-lazer-bin
    # X11 automation utilities
    xdotool
    xprop
    # Discord with OpenASAR (performance) + Vencord (client mods)
    (discord.override {
      withOpenASAR = true;
      withVencord  = true;
    })
  ];

  # ---------------------------------------------------------------------------
  # Programs
  # ---------------------------------------------------------------------------

  # nix-ld — lets unpatched/foreign ELF binaries find a dynamic linker.
  programs.nix-ld.enable = true;

  # Steam — open firewall ports for Remote Play, Source servers, and LAN transfers.
  programs.steam = {
    enable                                = true;
    remotePlay.openFirewall               = true;
    dedicatedServer.openFirewall          = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # ---------------------------------------------------------------------------
  # Services
  # ---------------------------------------------------------------------------

  # Flatpak — sandboxed app distribution.
  services.flatpak.enable = true;

  # ASUS DAMX laptop-control daemon (drivers installed via OEM, not Nix).
  services.damx = {
    enable         = true;
    installDrivers = false;
  };

  # Make sure the DAMX daemon can reach the tools it needs.
  systemd.services.damx-daemon.path = with pkgs; [
    sudo
    kmod
    systemd
    coreutils
  ];

  # services.openssh.enable = true;

  # ---------------------------------------------------------------------------
  # Firewall
  # ---------------------------------------------------------------------------

   networking.firewall.allowedTCPPorts = [ 32764 ];
   networking.firewall.allowedUDPPorts = [ 32764 ];
   networking.firewall.enable = true;

  # ---------------------------------------------------------------------------
  # State version
  # ---------------------------------------------------------------------------

  # This value determines which NixOS release the default settings for
  # stateful data (file locations, database versions, etc.) were taken from.
  # It is fine — and recommended — to leave it at the release version of your
  # first install.  Read the docs before changing it.
  system.stateVersion = "26.05";
}
