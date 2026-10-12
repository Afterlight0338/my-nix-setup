# my-nix-setup

```bash
curl -fsSL vivlos.dev/nix/install | bash
```

My NixOS config, and the Hyprland rice that goes with it: Caelestia shell, themed after Roxy Migurdia from *Mushoku Tensei*. Dark charcoal, Roxy blue, a little gold.

It runs my laptop (an Acer Nitro V 15, `hosts/nixos`), but the modules aren't tied to it, and `./setup` will write a config for your own machine.

> **Disclaimer.** This is a personal config, shared as is, with no warranty. I'm not responsible if it breaks, ruins, or changes your system, your boot, your files or your dotfiles in ways you didn't want. Read what you're about to run (the script is short), back up anything you care about, and use it at your own risk. NixOS keeps previous generations, so `sudo nixos-rebuild switch --rollback` is your way out.

## What you get

- **Hyprland** through UWSM, with the **Caelestia** shell (bar, launcher, notifications, lock screen)
- **Roxy theme** everywhere: GTK, Qt (Darkly with glass backgrounds), Papirus icons, kitty, fastfetch, btop, cava, Brave's toolbar, a boot splash
- **A settings page** for the rice (`Super + Shift + /`), so you don't have to edit config files for the common stuff
- **Gaming**: Steam, GameMode, osu! (lazer, plus stable through wine-osu)
- **Fixes for the usual NixOS annoyances**: downloaded binaries and AppImages just run, `, <command>` runs anything from nixpkgs once, `/tmp` gets cleaned, old generations get pruned weekly
- **Laptop bits**: NVIDIA PRIME (the dGPU sleeps when idle), the CachyOS kernel from a binary cache, Acer fan control (DAMX)

## Installing

On a working NixOS install, the one-liner at the top downloads this repo to `~/my-nix-setup` and starts the setup wizard. To pick the mode up front: `curl -fsSL vivlos.dev/nix/install | bash -s -- minimal`.

Or by hand (`vivlos.dev/nix` also redirects to the repo):

```bash
git clone https://github.com/Afterlight0338/my-nix-setup ~/my-nix-setup
cd ~/my-nix-setup
./setup            # or ./setup minimal
```

### The modes

The wizard detects your hardware (CPU, GPUs and the PRIME bus IDs of hybrid laptops, laptop or desktop, Acer, Bluetooth) and then asks for a mode. Each one only changes the config it writes for your machine; nothing is applied until you say so.

- **`lite`**: does nothing and exits. Nothing is written, nothing is installed. Why are you even using this script?
- **`minimal`**: only what's needed for the desktop: Hyprland through UWSM, the Caelestia shell with the Roxy theme and dotfiles, and osu! (lazer). No Steam, no extra apps, no file manager, no boot splash, no tablet driver, no custom kernel.
- **`full`**: the important parts of my system, nearly 1:1. Minimal plus Steam and GameMode, osu! stable through wine-osu, the desktop apps (Brave, Discord, mpv, ...), Flatpak, file managers, OpenTabletDriver with my area and filters, WebHID access for custom keyboards, the CachyOS kernel, the boot splash, and dev tools (dotnet, JDK, scrcpy, ani-cli, qemu). Acer fan control is added automatically on Acer laptops. Autologin stays off.
- **`afterlight`**: my actual host, 1:1, except passwords. Everything in `full`, plus what's in `hosts/nixos/personal.nix`: my external drives (mounted with `nofail`), the Kali VM bridge and NAT, autologin, Hamachi, my firewall ports and USB quirks, and the GRUB bridge if CachyOS's GRUB is found on your ESP. The user is `afterlight`, so set its password after switching with `sudo passwd afterlight`. Only pick this one if you really want my machine, not just my rice.

Hardware always comes from detection, never from my laptop: your own `hardware-configuration.nix`, your GPUs, your bus IDs.

### What the wizard does

It writes `hosts/<your hostname>/`, checks that the result builds, offers to copy the dotfiles into your home folder, and finally offers to switch. Nothing changes on your system until those last two questions, and anything it replaces is kept as `*.backup-<time>`. If your hostname is `nixos`, the config is written to `hosts/this-machine` because `hosts/nixos` is my laptop.

If something goes wrong after switching, `sudo nixos-rebuild switch --rollback` puts the previous system back, and older ones are in the boot menu.

## Day to day

```bash
sudo nixos-rebuild switch --flake ~/my-nix-setup#<hostname>   # apply changes
nix flake update                                               # newer packages (then rebuild)
```

Your machine's choices live in `hosts/<hostname>/default.nix`. The options are short and named after what they do (`custom.desktop.splash.enable`, `custom.hardware.nvidia.enable`, ...); `modules/*.nix` lists them all.

## Settings and hotkeys

Most of the rice can be changed from one page: `Super + Shift + /`, or the Settings button in the `Super + /` keybind cheat sheet. Simple and Advanced tabs, and changes apply live where they can. While you drag a slider the page turns see-through so you can watch the desktop change.

| Hotkey | What it does |
| :--- | :--- |
| `Super + /` | Keybind cheat sheet |
| `Super + Shift + /` | Settings |
| `Super + Shift + N` | Do Not Disturb |
| `Super + B` | Show the bar for a while |
| `Super + G` | Game mode (osu! turns it on by itself) |
| `Super + Shift + W` | Switch the `>wallpaper` picker between `~/Pictures/Wallpapers` and `~/Pictures/Wallpapers-q` |

In a terminal, `fastfetch-en` / `fastfetch-jp` switch the fastfetch box between English and Japanese, and `rice-settings get` / `rice-settings set KEY VALUE` do what the settings page does.

## Layout

```
flake.nix        inputs, and one nixosConfiguration per folder in hosts/
setup            the install wizard
modules/         core, desktop, hardware, gaming, apps (all options are custom.*)
hosts/nixos/     my laptop: default.nix (Acer hardware), personal.nix (the rest of my setup: drives, Kali VM network, ...)
hosts/generic/   fallback that uses /etc/nixos/hardware-configuration.nix
pkgs/            DAMX and the linuwu-sense driver (Acer)
dotfiles/        copied to ~/.config/<name>
home/            copied to ~/ (Settings backend and scripts, .zshrc, lock screen picture)
```

## Notes

- The CachyOS kernel and the Caelestia shell use their own pinned nixpkgs instead of following this one. That's what their binary caches were built with, so nothing gets compiled.
- My laptop boots through CachyOS's GRUB; `hosts/nixos/boot-bridge.nix` keeps its menu in sync with NixOS generations. A normal install doesn't need any of that.
- Monitors are auto-detected (preferred mode, placed automatically). Use `nwg-displays` or edit `~/.config/hypr` for a fixed layout.
- Hybrid AMD + NVIDIA laptops: set `custom.hardware.nvidia.prime.amdBusId` and `nvidiaBusId` (from `lspci`, written as `PCI:bus:device:function` in decimal) to let the NVIDIA GPU sleep and get `nvidia-offload <command>`.

MIT licensed. By Afterlight ([@Afterlight0338](https://github.com/Afterlight0338)).
