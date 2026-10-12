# my-nix-setup

My NixOS config, and the Hyprland rice that goes with it: Caelestia shell, themed after Roxy Migurdia from *Mushoku Tensei*. Dark charcoal, Roxy blue, a little gold.

It runs my laptop (an Acer Nitro V 15, `hosts/nixos`), but the modules aren't tied to it, and `./setup` will write a config for your own machine.

## What you get

- **Hyprland** through UWSM, with the **Caelestia** shell (bar, launcher, notifications, lock screen)
- **Roxy theme** everywhere: GTK, Qt (Darkly with glass backgrounds), Papirus icons, kitty, fastfetch, btop, cava, Brave's toolbar, a boot splash
- **A settings page** for the rice (`Super + Shift + /`), so you don't have to edit config files for the common stuff
- **Gaming**: Steam, GameMode, osu! (lazer, plus stable through wine-osu)
- **Fixes for the usual NixOS annoyances**: downloaded binaries and AppImages just run, `, <command>` runs anything from nixpkgs once, `/tmp` gets cleaned, old generations get pruned weekly
- **Laptop bits**: NVIDIA PRIME (the dGPU sleeps when idle), the CachyOS kernel from a binary cache, Acer fan control (DAMX)

## Installing

On a working NixOS install, one line:

```bash
curl -fsSL vivlos.dev/nix/install | bash
```

Or by hand (`vivlos.dev/nix` also redirects to the repo):

```bash
git clone https://github.com/Afterlight0338/my-nix-setup ~/my-nix-setup
cd ~/my-nix-setup
./setup
```

It looks at your hardware, asks what you want (everything, minimal, or one question per part), writes `hosts/<your hostname>/`, checks that it builds, offers to copy the dotfiles into your home folder, and finally offers to switch. Nothing changes until those last two questions, and anything it replaces is kept as `*.backup-<time>`.

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
hosts/nixos/     my laptop: drives, GRUB bridge, Kali VM network, personal packages
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
