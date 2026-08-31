# ❄️ Portable NixOS Flake & Roxy Hyprland Rice

> A modular, beginner-friendly NixOS configuration featuring an **interactive 1-click setup wizard** and a themed **Hyprland** desktop rice inspired by **Roxy Migurdia** (*Mushoku Tensei*).

---

## 🌟 For Beginners: "I Know Nothing About Nix"

Welcome! If you are new to Linux or NixOS, you do **not** need to edit code or learn Nix expressions to use this setup. The included wizard detects your hardware and configures your computer in **under 15 seconds**.

### 🚀 3-Step Guided Installation

1. **Install NixOS** on your computer using the standard NixOS installer.
2. **Open Terminal** and run:
   ```bash
   git clone https://github.com/Afterlight0338/my-nix-setup.git ~/nixos-config
   cd ~/nixos-config
   ./setup
   ```
   *(Alternatively, run directly with Nix: `nix run github:Afterlight0338/my-nix-setup`)*

3. **Press `[Enter]` to accept the defaults**:
   * **Profile Selection**: Defaults to `[1] 🚀 Full Experience` (Hyprland + Roxy Theme + Steam Gaming + osu! Lazer & osu-wine runner + Desktop Apps + Tablet).
   * **Username & Hostname**: Press `[Enter]` to keep your current username and computer name.
   * The wizard tests the configuration with Nix to ensure **zero errors**, installs the desktop theme, and switches to your new system!

---

### 🛡️ Safety & Undo (How Rollback Works)

One of the best features of NixOS is that **it never breaks your system permanently**:
* **Every change creates a "Generation"**: Whenever you update or configure your system, your previous working state is saved.
* **Boot Menu Rollback**: If your computer ever fails to boot or a graphics driver causes an issue, simply restart your computer and select any previous generation from the boot menu.
* **Instant Command Rollback**: To undo the last change from the terminal:
  ```bash
  sudo nixos-rebuild switch --rollback
  ```

---

### 🔄 How to Update Your System Later

Whenever you want to update your packages or apply changes:
```bash
cd ~/nixos-config
sudo nixos-rebuild switch --flake .
```

---
---

## 🛠️ For Power Users: "I Know Nix"

### Architecture & Flake Overview

This repository uses a pure NixOS Flake structure with dynamic host discovery and parameterized modules under the `custom.*` option namespace.

```text
my-nix-setup/
├── flake.nix                  # Pure flake with dynamic host auto-discovery
├── flake.lock                 # Pinned flake inputs (includes Caelestia CLI/Shell)
├── setup                      # Interactive 1-click preset setup wizard
├── .gitignore                 # Secrets & build artifact exclusions
│
├── hosts/                     # Machine-specific configurations
│   ├── nixos/                 # Primary host: Acer Nitro V 15 (Afterlight)
│   │   ├── default.nix        # Enabled feature toggles & host parameters
│   │   ├── hardware-configuration.nix # Disks, UUIDs, btrfs subvolumes
│   │   ├── boot-bridge.nix    # Dual-boot GRUB + systemd-boot integration
│   │   ├── generate-grub-direct.sh
│   │   └── drives.nix         # Host-specific partition mount points
│   │
│   └── generic/               # Fallback template importing /etc/nixos
│       ├── default.nix
│       └── hardware-configuration.nix
│
├── modules/                   # Parameterized NixOS system modules
│   ├── core/                  # Flakes, user management, locale, nix-ld, polkit, smart GC
│   ├── desktop/               # Hyprland (UWSM/Ozone), Roxy palette, fonts, Dolphin file manager, Caelestia Shell
│   ├── hardware/              # NVIDIA, AMD, Intel GPU, Bluetooth, PipeWire, OTD, WebHID, Laptop
│   ├── gaming/                # Steam, GameMode daemon, osu! Lazer, osu! Wine FHS runner, ProtonPlus, r2modman
│   ├── apps/                  # Brave, Discord (OpenASAR+Vencord), OBS virtual cam, Flatpak, Hamachi
│   └── system/                # Removable drive automount (udisks2/gvfs), drive helper script
│
├── pkgs/                      # Custom Nix derivations & overlays
│   ├── damx/                  # Linuwu-Sense kernel module, DAMX daemon & GUI
│   └── whatsapp-custom/       # Wayland-native WhatsApp desktop wrapper
│
└── dotfiles/                  # Rice configurations (Hyprland, Caelestia, QtEngine, Kitty, Fastfetch, OTD, etc.)
```

---

### Dynamic Host Discovery

`flake.nix` dynamically inspects `./hosts/` and creates a `nixosConfigurations.<hostname>` entry for every directory containing a `default.nix`. Creating a new host requires zero edits to `flake.nix`:

1. Run `nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware-configuration.nix`
2. Create `hosts/<hostname>/default.nix`
3. Stage with `git add hosts/<hostname>`
4. Rebuild: `sudo nixos-rebuild switch --flake .#<hostname>`

---

### Module Option Reference (`custom.*`)

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `custom.user.name` | `string` | `"nixos"` | Primary username created on the system |
| `custom.user.description` | `string` | `"NixOS User"` | User display name |
| `custom.desktop.hyprland.enable` | `bool` | `true` | Installs Hyprland with UWSM and Wayland utilities |
| `custom.desktop.theme.enable` | `bool` | `true` | Injects Roxy palette, Caelestia Shell/CLI, JetBrains Nerd Font |
| `custom.desktop.fileManager.enable`| `bool` | `true` | Dolphin, Thunar, Tumbler thumbnails, KIO plugins |
| `custom.hardware.nvidia.enable` | `bool` | `false` | NVIDIA proprietary drivers + VAAPI/VDPAU acceleration |
| `custom.hardware.amdGpu.enable` | `bool` | `false` | AMD Mesa & Vulkan graphics drivers |
| `custom.hardware.intelGpu.enable` | `bool` | `false` | Intel media driver & VAAPI acceleration |
| `custom.hardware.audio.enable` | `bool` | `true` | PipeWire + WirePlumber + ALSA/PulseAudio emulation |
| `custom.hardware.bluetooth.enable`| `bool` | `true` | Bluetooth service with power on boot |
| `custom.hardware.opentabletdriver.enable` | `bool` | `false` | OpenTabletDriver daemon with conflicting driver blacklist |
| `custom.hardware.opentabletdriver.preconfigure` | `bool` | `false` | Pre-configure tuned tablet area (67.67x39.39mm @ 180°) & filters |
| `custom.hardware.webhid.enable` | `bool` | `false` | WebHID/WebUSB udev rules (SayoDevice & AE68 Pro) |
| `custom.hardware.laptop.enable` | `bool` | `false` | UPower battery management service |
| `custom.hardware.laptop.damx` | `bool` | `false` | Acer DAMX fan & laptop management daemon |
| `custom.hardware.laptop.linuwuSense` | `bool` | `false` | Acer WMI kernel sensor module (`linuwu-sense`) |
| `custom.hardware.cachyosKernel.enable` | `bool` | `false` | CachyOS kernel with BORE CPU scheduler & binary cache |
| `custom.gaming.enable` | `bool` | `true` | Steam (open firewall), GameMode, ProtonPlus, r2modman |
| `custom.gaming.osu.enable` | `bool` | `false` | Master toggle for osu! rhythm game suite |
| `custom.gaming.osu.lazer` | `bool` | `true` | Install osu! Lazer (with Discord audio routing & Wayland optimization) |
| `custom.gaming.osu.wine` | `bool` | `false` | Enable osu-wine-nixos runner via Steam FHS (no system Wine installed) |
| `custom.apps.enable` | `bool` | `true` | Brave, Discord (OpenASAR+Vencord), media utilities |
| `custom.apps.flatpak.enable` | `bool` | `true` | Flatpak sandboxed application distribution |
| `custom.apps.hamachi.enable` | `bool` | `false` | LogMeIn Hamachi VPN service & Haguichi GUI |
| `custom.system.smartGc.enable` | `bool` | `true` | Weekly smart garbage collection (preserves last 3 gens) |
| `custom.system.automount.enable` | `bool` | `true` | Removable storage auto-discovery (udisks2/gvfs) |

---

## 🎨 Theme & Rice Details

The desktop environment is themed around **Roxy Migurdia** (*Mushoku Tensei: Jobless Reincarnation*), using a dark charcoal foundation paired with water-magic icy blues, soft cream text, and subdued gold/tan accents.

The palette is centralized in [`modules/desktop/roxy-palette.nix`](file:///home/afterlight/my-nix-setup/modules/desktop/roxy-palette.nix) and synchronized across Caelestia Shell, GTK (Adw-gtk3), Qt6 (Breeze + QtEngine), Fastfetch, Kitty, Btop, Cava, and Fuzzel.

---

## 👤 Credits

* **Author**: Afterlight ([@Afterlight0338](https://github.com/Afterlight0338))
* **Repository**: [https://github.com/Afterlight0338/my-nix-setup](https://github.com/Afterlight0338/my-nix-setup)
