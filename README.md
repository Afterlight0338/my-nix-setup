# ❄️ Portable & Reproducible NixOS Flake & Hyprland Rice

> A modular, reproducible NixOS flake configuration featuring a fully themed **Hyprland** desktop rice centered around the **Roxy Migurdia** (*Mushoku Tensei*) color palette. Designed to be portable across different hardware platforms (NVIDIA, AMD, Intel, Laptops, Desktops) while providing an out-of-the-box daily driver workstation.

---

## 🌟 Overview & Highlights

* **100% Pure Nix Flake**: Fully declarative, pinned inputs, reproducible across any x86_64-linux (and compatible) machine.
* **Separation of Concerns**: Clear separation between core system settings, desktop environment, gaming stack, user applications, and host-specific hardware configurations.
* **Modular Hardware Support**:
  * **NVIDIA / AMD / Intel GPUs**: Simple toggle options for graphics drivers, hardware video acceleration (VAAPI/VDPAU), and Wayland compatibility.
  * **Peripherals**: OpenTabletDriver (custom tablet area mappings), WebHID / WebUSB udev rules (SayoDevice K05 HE, Everglide AE68 Pro).
  * **Laptop Control**: Power management (UPower), Acer/ASUS WMI sensor modules (`linuwu-sense`), and DAMX daemon management.
  * **Optimized Kernels**: Optional CachyOS kernel with BORE CPU scheduler and binary cache integration.
* **Desktop Rice (Roxy Palette)**:
  * **Compositor**: Hyprland (with UWSM, XWayland, Ozone Wayland defaults).
  * **Themes & Polish**: Consistent Roxy Migurdia palette across GTK, Qt (QtEngine/Breeze), Dolphin, Fastfetch, Kitty, Fuzzel, Btop, and Cava.
  * **Smart GC**: Automated weekly garbage collection service preserving the last 3 generations and pruning older unreferenced store paths (>14 days).

---

## 📁 Repository Structure

```text
my-nix-setup/
├── flake.nix                  # Flake inputs, system outputs, and exported modules
├── flake.lock                 # Pinned dependencies
├── .gitignore                 # Ignore secrets, build outputs, and temporary files
│
├── hosts/                     # Machine-specific configurations
│   ├── nixos/                 # Primary host: Acer Nitro V 15 (Afterlight)
│   │   ├── default.nix        # Host entrypoint & enabled feature flags
│   │   ├── hardware-configuration.nix # Disks, UUIDs, btrfs subvolumes
│   │   ├── boot-bridge.nix    # Dual-boot GRUB + systemd-boot integration
│   │   ├── generate-grub-direct.sh
│   │   └── drives.nix         # Custom partition mount points
│   │
│   └── generic/               # Portable template host for any new machine
│       ├── default.nix        # Clean fallback importing /etc/nixos/hardware-configuration.nix
│       └── hardware-configuration.nix # Safe minimal fallback mounts
│
├── modules/                   # Reusable NixOS system modules
│   ├── core/                  # Flake settings, locale, user management, nix-ld, polkit, smart GC
│   ├── desktop/               # Hyprland compositor, Roxy theme palette, fonts, file manager (Dolphin)
│   ├── hardware/              # NVIDIA, AMD, Intel GPU, Bluetooth, PipeWire audio, OpenTabletDriver, WebHID, Laptop
│   ├── gaming/                # Steam (firewall rules), GameMode, osu! Lazer, ProtonPlus, r2modman
│   ├── apps/                  # Brave, Discord (OpenASAR+Vencord), OBS virtual cam, Hamachi, user utilities
│   └── system/                # Removable drive automount (udisks2/gvfs), drive helper script
│
├── pkgs/                      # Custom package definitions & overlays
│   ├── damx/                  # Linuwu-Sense kernel module, DAMX daemon, DAMX GUI
│   └── whatsapp-custom/       # Wayland-native WhatsApp desktop wrapper
│
└── dotfiles/                  # User space configuration files & rice assets
    ├── hypr/                  # Hyprland keybinds, animations, and monitor configurations
    ├── OpenTabletDriver/      # Tablet area, filters, and output settings
    ├── fastfetch/             # Custom Roxy ASCII & system specs layout
    ├── kitty/                 # Terminal styling
    ├── fuzzel/                # Application launcher styling
    ├── btop/                  # Resource monitor theme
    ├── cava/                  # Audio visualizer shaders & colors
    └── zsh/                   # Zsh shell aliases and utilities
```

---

## 🚀 Quick Start & Installation

### Option A: Testing / Using the Generic Template on a Fresh NixOS Install

1. **Install NixOS** with standard UEFI / systemd-boot.
2. **Enable Flakes** temporarily (if not already enabled):
   ```bash
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
   ```
3. **Clone the repository**:
   ```bash
   git clone https://github.com/Afterlight0338/my-nix-setup.git ~/nixos-config
   cd ~/nixos-config
   ```
4. **Build and switch**:
   ```bash
   sudo nixos-rebuild switch --flake .#generic
   ```
   *(The `generic` configuration automatically uses `/etc/nixos/hardware-configuration.nix` if it exists on your machine).*

---

### Option B: Creating a Custom Host for Your Machine

1. **Generate your hardware configuration**:
   ```bash
   mkdir -p hosts/my-pc
   nixos-generate-config --show-hardware-config > hosts/my-pc/hardware-configuration.nix
   ```

2. **Create `hosts/my-pc/default.nix`**:
   ```nix
   { pkgs, lib, ... }:

   {
     imports = [
       ./hardware-configuration.nix
     ];

     networking.hostName = "my-pc";

     # Customize your user
     custom.user.name = "yourusername";
     custom.user.description = "Your Name";

     # Toggle hardware features
     custom.hardware = {
       # Set your GPU driver
       nvidia.enable = true; # Or amdGpu.enable = true / intelGpu.enable = true
       bluetooth.enable = true;
       audio.enable = true;
       laptop.enable = false; # Set true if configuring a laptop
     };

     # Optional feature toggles (all default to true)
     custom.desktop.hyprland.enable = true;
     custom.gaming.enable = true;
     custom.apps.enable = true;

     # Standard bootloader
     boot.loader.systemd-boot.enable = true;
     boot.loader.efi.canTouchEfiVariables = true;

     system.stateVersion = "26.05";
   }
   ```

3. **Add your host to `flake.nix`**:
   Inside `nixosConfigurations` in `flake.nix`:
   ```nix
   my-pc = mkHost {
     hostname = "my-pc";
   };
   ```

4. **Rebuild the system**:
   ```bash
   git add hosts/my-pc
   sudo nixos-rebuild switch --flake .#my-pc
   ```

---

## ⚙️ Modular Feature Reference (`custom.*`)

All features are controlled through clean, typed options:

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `custom.user.name` | `string` | `"afterlight"` / `"nixos"` | Primary username created on the system |
| `custom.desktop.hyprland.enable` | `bool` | `true` | Installs Hyprland, UWSM, XWayland & Wayland utilities |
| `custom.desktop.theme.enable` | `bool` | `true` | Injects Roxy palette, JetBrains Mono Nerd Font, Noto fonts |
| `custom.desktop.fileManager.enable`| `bool` | `true` | Dolphin, Thunar, Tumbler thumbnails, KIO integration |
| `custom.hardware.nvidia.enable` | `bool` | `false` | NVIDIA proprietary drivers + VAAPI/VDPAU acceleration |
| `custom.hardware.amdGpu.enable` | `bool` | `false` | AMD Mesa & Vulkan drivers |
| `custom.hardware.intelGpu.enable` | `bool` | `false` | Intel media & VAAPI drivers |
| `custom.hardware.audio.enable` | `bool` | `true` | PipeWire + WirePlumber + ALSA/PulseAudio emulation |
| `custom.hardware.bluetooth.enable`| `bool` | `true` | Bluetooth service with power on boot |
| `custom.hardware.opentabletdriver.enable` | `bool` | `true` | OTD daemon with conflicting driver blacklist |
| `custom.hardware.webhid.enable` | `bool` | `true` | WebHID/WebUSB udev rules (SayoDevice & AE68 Pro) |
| `custom.hardware.laptop.enable` | `bool` | `false` | UPower and power profile daemons |
| `custom.hardware.laptop.damx` | `bool` | `false` | Acer DAMX fan & laptop management service |
| `custom.hardware.laptop.linuwuSense` | `bool` | `false` | Acer WMI kernel module (`linuwu-sense`) |
| `custom.hardware.cachyosKernel.enable` | `bool` | `false` | CachyOS BORE scheduler kernel + binary cache |
| `custom.gaming.enable` | `bool` | `true` | Steam, GameMode, osu! Lazer, ProtonPlus, r2modman |
| `custom.apps.enable` | `bool` | `true` | Brave, Discord (OpenASAR+Vencord), OBS virtual cam |
| `custom.system.smartGc.enable` | `bool` | `true` | Weekly smart garbage collection (preserves 3 gens) |
| `custom.system.automount.enable` | `bool` | `true` | Removable storage auto-discovery & mounting |

---

## 🎨 Applying Dotfiles

The `dotfiles/` directory contains matching application configs:
* **Hyprland**: Link or copy `dotfiles/hypr/` to `~/.config/hypr/`
* **Kitty**: Link or copy `dotfiles/kitty/` to `~/.config/kitty/`
* **Fastfetch**: Link or copy `dotfiles/fastfetch/` to `~/.config/fastfetch/`
* **OpenTabletDriver**: Link or copy `dotfiles/OpenTabletDriver/` to `~/.config/OpenTabletDriver/`
* **Btop / Fuzzel / Cava**: Link respective directories to `~/.config/`

---

## 🔄 Updating & Maintenance

* **Update all flake inputs**:
  ```bash
  nix flake update
  ```
* **Verify configuration without switching**:
  ```bash
  nix flake check
  ```
* **Rebuild system**:
  ```bash
  sudo nixos-rebuild switch --flake .
  ```

---

## 👤 Author & Credits

* **Author**: Afterlight ([@Afterlight0338](https://github.com/Afterlight0338))
* **Theme Reference**: Roxy Migurdia (*Mushoku Tensei: Jobless Reincarnation*)
* **Repository**: [https://github.com/Afterlight0338/my-nix-setup](https://github.com/Afterlight0338/my-nix-setup)
