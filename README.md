# Afterlight's NixOS & Hyprland Rice Setup ❄️💧

> Declarative NixOS configuration, Hyprland window manager rice, and hardware setups for **Afterlight**. Themed around **Roxy Migurdia** (*Mushoku Tensei* Water Holy Class Mage).

---

## 🖥️ System & Hardware Specifications

| Component | Hardware / Model | Configuration / Details |
| :--- | :--- | :--- |
| **Host System** | Acer Nitro V 15 | AMD Ryzen 5 7535HS, 32GB DDR5, RTX 3050 6GB + Radeon 680M |
| **OS / Init** | NixOS 26.05 | Declarative NixOS Flake & System Configuration |
| **Window Manager** | Hyprland | Dynamic tiling, smooth animations, Caelestia / Roxy palette |
| **Primary Display** | **AOC 24G11ZE** | 1920×1080 @ **240 Hz** (`HDMI-A-1, 1920x1080@240.0, 0x0, 1.0`) |
| **Laptop Display** | Internal Panel | 1920×1080 @ **165 Hz** (`eDP-1, 1920x1080@165.0, 1920x0, 1.0`) |
| **Keypad** | **SayoDevice K05 HE** | Hall Effect Rapid Trigger Keypad (`1.5mm` Actuation, `0.3mm` Release, `0.4mm` RT Release, `0.2mm` RT Actuation) |
| **Tablet** | **Wacom CTH-670** | Active Area: `67.67 × 39.39 mm` (1.718 : 1 aspect ratio, 180° rotation, OpenTabletDriver) |
| **Main Keyboard** | **Everglide AE68 PRO** | 68-Key Compact Board with WebHID / WebUSB Udev access |

---

## 📁 Repository Structure

```text
my-nix-setup/
├── README.md
├── nixos/
│   ├── configuration.nix       # Main declarative NixOS system config
│   ├── hardware-configuration.nix # Kernel modules, filesystems, swap
│   ├── hardware-desktop.nix    # Desktop GPU & display hardware profile
│   ├── webhid.nix              # WebHID/WebUSB udev rules for SayoDevice K05 HE & Everglide AE68 Pro
│   ├── roxy-palette.nix        # Roxy Migurdia water & sapphire theme color palette
│   ├── caelestia-theme.nix     # Hyprland / Caelestia desktop theme integration
│   ├── desktop-apps.nix        # System desktop applications
│   ├── file-manager.nix        # File manager integration
│   ├── user-packages.nix       # User packages & development tools
│   ├── drives.nix              # Drive mount mappings
│   ├── drive-script.nix        # Automated disk & mount scripts
│   ├── automount.nix           # Auto-mounting service
│   ├── boot-bridge.nix         # Bootloader bridge config
│   ├── shell.nix               # Shell environment
│   └── generate-grub-direct.sh # Direct GRUB configuration script
└── dotfiles/
    ├── hypr/                   # Hyprland configs (hyprland.lua, monitors.conf, variables.lua)
    ├── OpenTabletDriver/       # OTD tablet area (67.67x39.39mm), filters, and display mappings
    ├── fastfetch/              # Custom Roxy Migurdia fastfetch ASCII config
    ├── kitty/                  # Terminal emulator config
    ├── fuzzel/                 # Application launcher config
    ├── btop/                   # System monitor styling
    ├── cava/                   # Audio visualizer config
    └── zsh/                    # Zsh shell configuration & helper scripts
```

---

## 🎮 Input & Peripheral Details

### SayoDevice K05 HE (Hall Effect + Rapid Trigger)
* **WebHID / WebUSB Udev Rules**: Configured in `nixos/webhid.nix` (`ATTRS{idVendor}=="8089", ATTRS{idProduct}=="0009"`).
* Continuous analog physical travel range from $0.0\text{mm}$ to $4.0\text{mm}$.
* Actuation point: $1.5\text{mm}$
* Release threshold: $0.3\text{mm}$
* Rapid Trigger release: $0.4\text{mm}$
* Rapid Trigger actuation: $0.2\text{mm}$

### Wacom CTH-670 (OpenTabletDriver)
* Configured in `dotfiles/OpenTabletDriver/settings.json`.
* Active mapping: `67.67 × 39.39 mm` positioned at `(X: 108.24, Y: 68.5)` with $180.0^\circ$ rotation.
* Output Mode: `OpenTabletDriver.Desktop.Output.LinuxArtistMode`.
* Filters: `TemporalResampler` @ 1000 Hz, `RadialFollowSmoothingTabletSpace`.

---

## 🔗 Related Projects & Links

* 🌐 **Personal Sanctuary & Dashboard**: [Afterlight0338.github.io](https://github.com/Afterlight0338/Afterlight0338.github.io)
* 🎨 **Roxy Fastfetch Config**: [roxy-fastfetch](https://github.com/Afterlight0338/roxy-fastfetch)
* 🎯 **osu! Skins Collection**: [osu-skins](https://github.com/Afterlight0338/osu-skins)
* 👤 **GitHub Profile**: [@Afterlight0338](https://github.com/Afterlight0338)
