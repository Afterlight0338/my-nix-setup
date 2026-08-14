# Small yay/pacman compatibility wrapper for Nix.
# Declarative version: -S / -R edit /etc/nixos/user-packages.nix and rebuild.

_yay_resolve_pkg() {
  # Try to find a valid attribute path for a bare package name.
  # Prints the resolved attribute (possibly with a namespace prefix) or
  # nothing if it can't be resolved at all.
  local pkg="$1"

  if nix eval --impure --expr "with import <nixpkgs> {}; ${pkg}" &>/dev/null; then
    echo "$pkg"
    return 0
  fi

  local ns
  for ns in kdePackages gnome python3Packages nodePackages; do
    if nix eval --impure --expr "with import <nixpkgs> {}; ${ns}.${pkg}" &>/dev/null; then
      echo "${ns}.${pkg}"
      return 0
    fi
  done

  return 1
}

yay() {
  if (( $# == 0 )); then
    yay --help
    return
  fi

  local pkgfile="/etc/nixos/user-packages.nix"

  case "$1" in
    -S)
      shift

      if (( $# == 0 )); then
        echo "error: no packages specified"
        return 1
      fi

      if [[ ! -f "$pkgfile" ]]; then
        echo "error: $pkgfile not found. Create it and add it to your imports first."
        return 1
      fi

      local package resolved
      local -a to_add

      for package in "$@"; do
        if grep -qE "(^|\.)${package}\s*\$" "$pkgfile"; then
          echo "already declared: $package"
          continue
        fi

        echo "resolving: $package ..."
        resolved="$(_yay_resolve_pkg "$package")"

        if [[ -z "$resolved" ]]; then
          echo "error: could not resolve '$package' in nixpkgs (checked top-level, kdePackages, gnome, python3Packages, nodePackages). Skipping."
          continue
        fi

        if [[ "$resolved" != "$package" ]]; then
          echo "note: '$package' resolved as '$resolved'"
        fi

        to_add+=("$resolved")
      done

      if (( ${#to_add[@]} == 0 )); then
        echo "nothing new to add"
        return 0
      fi

      for package in "${to_add[@]}"; do
        sudo sed -i "s/# yay-managed packages below.*/&\n    ${package}/" "$pkgfile"
      done

      echo "Added: ${to_add[*]}"
      echo "Rebuilding NixOS..."
      sudo nixos-rebuild switch
      ;;

    -Ss)
      shift

      if (( $# == 0 )); then
        echo "error: no search query specified"
        return 1
      fi

      nix search nixpkgs "$*"
      ;;

    -Q)
      if [[ -f "$pkgfile" ]]; then
        echo "--- Declarative (user-packages.nix) ---"
        grep -E "^\s*[a-zA-Z0-9_.-]+\s*\$" "$pkgfile" | sed 's/^\s*/  /'
      fi
      echo "--- Imperative (nix profile) ---"
      nix profile list
      ;;

    -R|-Rs|-Rns)
      shift

      if (( $# == 0 )); then
        echo "error: no packages specified"
        return 1
      fi

      if [[ ! -f "$pkgfile" ]]; then
        echo "error: $pkgfile not found."
        return 1
      fi

      local package
      local -a removed

      for package in "$@"; do
        if grep -qE "(^|\.)${package}\s*\$" "$pkgfile"; then
          sudo sed -i -E "/(^|\.)${package}[[:space:]]*\$/d" "$pkgfile"
          removed+=("$package")
        else
          echo "not declared in $pkgfile, skipping: $package"
        fi
      done

      if (( ${#removed[@]} == 0 )); then
        echo "nothing removed"
        return 0
      fi

      echo "Removed: ${removed[*]}"
      echo "Rebuilding NixOS..."
      sudo nixos-rebuild switch
      ;;

    -Syu|-Syyu)
      echo "Updating the NixOS system..."
      sudo nixos-rebuild switch --upgrade || return

      echo "Updating user-profile packages..."
      NIXPKGS_ALLOW_UNFREE=1 nix profile upgrade --all --impure
      ;;

    -h|--help)
      cat <<'HELP'
Fake yay wrapper for NixOS (declarative mode)

  yay -S package...    Validate + add packages to user-packages.nix, then rebuild
  yay -Ss query        Search Nixpkgs
  yay -Q               List declarative + imperative packages
  yay -R package...    Remove packages from user-packages.nix and rebuild
  yay -Rns package...  Same as -R under this wrapper
  yay -Syu             Upgrade NixOS and profile packages

Packages are checked with 'nix eval' before being written, and namespaced
packages (kdePackages.*, gnome.*, python3Packages.*, nodePackages.*) are
auto-detected. Requires sudo for -S/-R (edits /etc/nixos and rebuilds).
HELP
      ;;

    *)
      echo "Unsupported yay operation: $1"
      echo "Run: yay --help"
      return 1
      ;;
  esac
}

pacman() {
  yay "$@"
}
