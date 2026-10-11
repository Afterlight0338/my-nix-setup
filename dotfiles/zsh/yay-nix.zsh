# ==============================================================================
# Yay / Pacman Compatibility Wrapper for NixOS (Declarative)
# ==============================================================================

_yay_colors() {
  BOLD=$'\e[1m'
  CYAN=$'\e[1;36m'
  BLUE=$'\e[1;34m'
  GREEN=$'\e[1;32m'
  YELLOW=$'\e[1;33m'
  RED=$'\e[1;31m'
  RESET=$'\e[0m'
}

_yay_read_input() {
  local default_val="$1"
  local res=""
  if read -r res; then
    echo "${res:-$default_val}"
  else
    echo "$default_val"
  fi
}

# Path to the root channel generation the running system was built from.
# -S/-R rebuild against it so they never pull in a newer, un-applied channel.
_yay_system_nixpkgs() {
  _yay_colors
  local rev link
  rev="$(nixos-version --revision 2>/dev/null)"

  if [[ -n "$rev" ]]; then
    for link in /nix/var/nix/profiles/per-user/root/channels-*-link(NnOn); do
      if [[ -r "$link/nixos/.git-revision" && "$(<"$link/nixos/.git-revision")" == "$rev" ]]; then
        echo "$link/nixos"
        return 0
      fi
    done
  fi

  printf "%serror:%s can't find the nixpkgs channel your current system was built from (%s).\n" "$RED" "$RESET" "${rev:-unknown}" >&2
  printf "       Run 'yay -Syu' to upgrade first, so -S/-R don't pull in updates.\n" >&2
  return 1
}

# Channel generation number currently active for root (e.g. 4 for channels-4-link).
_yay_channel_gen() {
  local link
  link="$(readlink /nix/var/nix/profiles/per-user/root/channels)" || return 1
  link="${link#channels-}"
  echo "${link%-link}"
}

_yay_resolve_pkg() {
  local pkg="$1"
  _yay_colors

  # 1. Direct explicit attribute path (e.g. kdePackages.kate or python3Packages.requests)
  if [[ "$pkg" == *.* ]]; then
    if nix eval "${_yay_nix_I[@]}" --impure --expr "(import <nixpkgs> {}).${pkg} or null != null" 2>/dev/null | grep -q "true"; then
      echo "$pkg"
      return 0
    fi
    printf "%serror:%s package attribute '%s' not found in nixpkgs.\n" "$RED" "$RESET" "$pkg" >&2
    return 1
  fi

  # 2. Search for exact and matching candidates in nixpkgs
  local candidates_raw
  candidates_raw=$(nix-instantiate "${_yay_nix_I[@]}" --eval --strict --json -E "
    let
      pkgs = import <nixpkgs> {};
      q = \"${pkg}\";
      # Exact top match
      exactTop = if (pkgs ? \"\${q}\") then [ q ] else [];
      # Exact namespace match (e.g. kdePackages.kate)
      exactKde = if (pkgs ? kdePackages && pkgs.kdePackages ? \"\${q}\") then [ \"kdePackages.\${q}\" ] else [];
      exactGnome = if (pkgs ? gnome && pkgs.gnome ? \"\${q}\") then [ \"gnome.\${q}\" ] else [];
      exactPython = if (pkgs ? python3Packages && pkgs.python3Packages ? \"\${q}\") then [ \"python3Packages.\${q}\" ] else [];
      
      # Partial/substring matches
      top = builtins.filter (n: n != q && builtins.match (\".*\" + q + \".*\") n != null) (builtins.attrNames pkgs);
      kde = builtins.map (n: \"kdePackages.\" + n) (builtins.filter (n: n != q && builtins.match (\".*\" + q + \".*\") n != null) (builtins.attrNames (pkgs.kdePackages or {})));
      gnome = builtins.map (n: \"gnome.\" + n) (builtins.filter (n: n != q && builtins.match (\".*\" + q + \".*\") n != null) (builtins.attrNames (pkgs.gnome or {})));
      python = builtins.map (n: \"python3Packages.\" + n) (builtins.filter (n: n != q && builtins.match (\".*\" + q + \".*\") n != null) (builtins.attrNames (pkgs.python3Packages or {})));
    in exactTop ++ exactKde ++ exactGnome ++ exactPython ++ kde ++ gnome ++ python ++ top
  " 2>/dev/null)

  if [[ -z "$candidates_raw" || "$candidates_raw" == "[]" ]]; then
    printf "%serror:%s target not found: %s\n" "$RED" "$RESET" "$pkg" >&2
    return 1
  fi

  # Parse JSON array into zsh array (deduplicated)
  local -a candidates
  candidates=($(echo "$candidates_raw" | jq -r '.[]' 2>/dev/null | awk '!seen[$0]++'))
  local count=${#candidates[@]}

  if (( count == 0 )); then
    printf "%serror:%s target not found: %s\n" "$RED" "$RESET" "$pkg" >&2
    return 1
  fi

  # If exactly 1 candidate
  if (( count == 1 )); then
    echo "${candidates[1]}"
    return 0
  fi

  # If first candidate is an exact match and no other ambiguous variants needed
  if [[ "${candidates[1]}" == "$pkg" || "${candidates[1]}" == "kdePackages.${pkg}" ]]; then
    local has_close_variants=0
    for cand in "${candidates[@]:1:10}"; do
      if [[ "$cand" == *"${pkg}-"* || "$cand" == *"/${pkg}"* ]]; then
        has_close_variants=1
        break
      fi
    done

    # If no close alternatives, use the exact match directly
    if (( has_close_variants == 0 )); then
      echo "${candidates[1]}"
      return 0
    fi
  fi

  # Interactive selection menu like Arch yay
  printf "%s::%s %sThere are %d providers available for '%s':%s\n" "$BLUE" "$RESET" "$BOLD" "$count" "$pkg" "$RESET" >&2
  printf "%s:: Repository nixpkgs:%s\n" "$CYAN" "$RESET" >&2

  local i=1
  local limit=25
  for cand in "${candidates[@]}"; do
    if (( i == 1 )); then
      printf "   %s%2d)%s %s%s%s (default)\n" "$CYAN" "$i" "$RESET" "$BOLD" "$cand" "$RESET" >&2
    else
      printf "   %s%2d)%s %s\n" "$CYAN" "$i" "$RESET" "$cand" >&2
    fi
    (( i++ ))
    if (( i > limit )); then
      printf "   %s... and %d more (showing top %d)%s\n" "$YELLOW" "$(( count - limit ))" "$limit" "$RESET" >&2
      break
    fi
  done

  printf "\n%sEnter a number (default=1, q to cancel):%s " "$BOLD" "$RESET" >&2
  local choice
  choice=$(_yay_read_input "1")

  if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
    printf "%sAborted.%s\n" "$YELLOW" "$RESET" >&2
    return 1
  fi

  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= count )); then
    echo "${candidates[$choice]}"
    return 0
  else
    printf "%serror:%s invalid selection\n" "$RED" "$RESET" >&2
    return 1
  fi
}

# Undo a channel update that was never applied, so the channel keeps matching the system.
_yay_restore_channel() {
  local old_gen="$1" new_gen="$2"
  [[ -n "$old_gen" && "$old_gen" != "$new_gen" ]] || return 0
  printf "%s::%s Restoring nixpkgs channel to the version your system is running...\n" "$BLUE" "$RESET"
  sudo nix-env -p /nix/var/nix/profiles/per-user/root/channels --switch-generation "$old_gen" >/dev/null
}

yay() {
  _yay_colors

  if (( $# == 0 )); then
    yay --help
    return
  fi

  local pkgfile="/etc/nixos/user-packages.nix"

  case "$1" in
    -S)
      shift
      if (( $# == 0 )); then
        printf "%serror:%s no packages specified\n" "$RED" "$RESET"
        return 1
      fi

      if [[ ! -f "$pkgfile" ]]; then
        printf "%serror:%s %s not found.\n" "$RED" "$RESET" "$pkgfile"
        return 1
      fi

      # Build against the nixpkgs the running system uses: add only, no upgrades
      local pin
      pin="$(_yay_system_nixpkgs)" || return 1
      local -a _yay_nix_I=(-I "nixpkgs=$pin")

      local package resolved
      local -a to_add

      for package in "$@"; do
        if grep -qE "^\s*(${package}|${package}\s*#)" "$pkgfile"; then
          printf "%swarning:%s %s is already declared in %s\n" "$YELLOW" "$RESET" "$package" "$pkgfile"
          continue
        fi

        printf "%s::%s Resolving package '%s'...\n" "$BLUE" "$RESET" "$package"
        resolved="$(_yay_resolve_pkg "$package")" || continue

        if [[ -z "$resolved" ]]; then
          continue
        fi

        if grep -qE "^\s*(${resolved}|${resolved}\s*#)" "$pkgfile"; then
          printf "%swarning:%s %s is already declared as '%s'\n" "$YELLOW" "$RESET" "$package" "$resolved"
          continue
        fi

        if [[ "$resolved" != "$package" ]]; then
          printf "%s==>%s Selected: %s%s%s (for '%s')\n" "$GREEN" "$RESET" "$BOLD" "$resolved" "$RESET" "$package"
        fi

        to_add+=("$resolved")
      done

      if (( ${#to_add[@]} == 0 )); then
        printf "%s::%s Nothing new to add.\n" "$BLUE" "$RESET"
        return 0
      fi

      printf "\n%sPackages to install (%d):%s %s\n\n" "$BOLD" "${#to_add[@]}" "$RESET" "${to_add[*]}"
      printf "%sProceed with installation? [Y/n]%s " "$BOLD" "$RESET"
      local confirm
      confirm=$(_yay_read_input "Y")
      if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        printf "%sOperation cancelled.%s\n" "$YELLOW" "$RESET"
        return 0
      fi

      for package in "${to_add[@]}"; do
        sudo sed -i "/\s*\];/i \    ${package}" "$pkgfile"
      done

      printf "%s::%s %sRebuilding NixOS system...%s\n" "$BLUE" "$RESET" "$BOLD" "$RESET"
      sudo nixos-rebuild switch "${_yay_nix_I[@]}"
      ;;

    -Ss)
      shift
      if (( $# == 0 )); then
        printf "%serror:%s no search query specified\n" "$RED" "$RESET"
        return 1
      fi
      printf "%s::%s Searching nixpkgs for '%s'...\n" "$BLUE" "$RESET" "$*"
      nix search nixpkgs "$*"
      ;;

    -Si|-Qi)
      shift
      if (( $# == 0 )); then
        printf "%serror:%s no package specified\n" "$RED" "$RESET"
        return 1
      fi
      local q="$1"
      nix eval --json --impure --expr "
        let
          pkgs = import <nixpkgs> {};
          p = pkgs.${q} or (pkgs.kdePackages.${q} or null);
        in if p == null then null else {
          name = p.name or p.pname or \"unknown\";
          version = p.version or \"unknown\";
          description = p.meta.description or \"No description\";
          homepage = p.meta.homepage or \"None\";
          license = if (p.meta ? license) then (if (builtins.isList p.meta.license) then (builtins.map (l: l.shortName or l.fullName or \"custom\") p.meta.license) else (p.meta.license.shortName or p.meta.license.fullName or \"custom\")) else \"unknown\";
        }
      " 2>/dev/null | jq .
      ;;

    -Q|-Qe)
      if [[ -f "$pkgfile" ]]; then
        printf "%s=== Declarative Packages (%s) ===%s\n" "$CYAN" "$pkgfile" "$RESET"
        grep -E "^\s*[a-zA-Z0-9_.-]+(\.[a-zA-Z0-9_.-]+)*" "$pkgfile" | grep -vE "environment.systemPackages|pkgs" | sed 's/^\s*/  /'
      fi
      printf "\n%s=== Imperative Packages (nix profile) ===%s\n" "$CYAN" "$RESET"
      nix profile list 2>/dev/null || true
      ;;

    -R|-Rs|-Rns)
      shift
      if (( $# == 0 )); then
        printf "%serror:%s no packages specified\n" "$RED" "$RESET"
        return 1
      fi

      if [[ ! -f "$pkgfile" ]]; then
        printf "%serror:%s %s not found.\n" "$RED" "$RESET" "$pkgfile"
        return 1
      fi

      # Build against the nixpkgs the running system uses: remove only, no upgrades
      local pin
      pin="$(_yay_system_nixpkgs)" || return 1
      local -a _yay_nix_I=(-I "nixpkgs=$pin")

      local package
      local -a removed

      for package in "$@"; do
        if grep -qE "^\s*(${package}|${package}\s*#)" "$pkgfile"; then
          sudo sed -i -E "/^[[:space:]]*${package}([[:space:]]*#.*)?$/d" "$pkgfile"
          removed+=("$package")
        else
          printf "%swarning:%s not declared in %s, skipping: %s\n" "$YELLOW" "$RESET" "$pkgfile" "$package"
        fi
      done

      if (( ${#removed[@]} == 0 )); then
        printf "%s::%s Nothing removed.\n" "$BLUE" "$RESET"
        return 0
      fi

      printf "%s==>%s Removed: %s%s%s\n" "$GREEN" "$RESET" "$BOLD" "${removed[*]}" "$RESET"
      printf "%s::%s %sRebuilding NixOS system...%s\n" "$BLUE" "$RESET" "$BOLD" "$RESET"
      sudo nixos-rebuild switch "${_yay_nix_I[@]}"
      ;;

    -Syu|-Syyu)
      printf "\n%s::%s %sSynchronizing package databases...%s\n" "$BLUE" "$RESET" "$BOLD" "$RESET"
      local old_gen new_gen
      old_gen="$(_yay_channel_gen)"
      sudo nix-channel --update || return 1
      new_gen="$(_yay_channel_gen)"

      printf "\n%s::%s %sStarting full system upgrade...%s\n" "$BLUE" "$RESET" "$BOLD" "$RESET"
      printf "%s::%s Resolving dependencies and checking package changes...\n\n" "$BLUE" "$RESET"

      # Build new system generation staging in temporary dir
      local tmp_dir
      tmp_dir=$(mktemp -d /tmp/nixos-upgrade.XXXXXX)

      if ! ( cd "$tmp_dir" && sudo nixos-rebuild build ); then
        printf "\n%serror:%s failed to evaluate / build upgrade\n" "$RED" "$RESET"
        rm -rf "$tmp_dir"
        _yay_restore_channel "$old_gen" "$new_gen"
        return 1
      fi

      local result_link="$tmp_dir/result"

      # Compute Version Diff and Size Delta using nvd
      printf "\n%s=========================== Upgrade Preview ===========================%s\n" "$CYAN" "$RESET"
      nix-shell -p nvd --run "nvd diff /run/current-system $result_link"
      printf "%s=======================================================================%s\n\n" "$CYAN" "$RESET"

      printf "%s:: Proceed with installation? [Y/n]%s " "$BOLD" "$RESET"
      local confirm
      confirm=$(_yay_read_input "Y")

      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        printf "\n%s::%s %sApplying system upgrade...%s\n" "$BLUE" "$RESET" "$BOLD" "$RESET"
        sudo nixos-rebuild switch

        # Update imperative profile packages if any
        if nix profile list &>/dev/null; then
          printf "\n%s::%s Updating user profile packages...\n" "$BLUE" "$RESET"
          NIXPKGS_ALLOW_UNFREE=1 nix profile upgrade --all --impure 2>/dev/null || true
        fi

        printf "\n%s::%s %sUpgrade complete!%s\n" "$GREEN" "$RESET" "$BOLD" "$RESET"
      else
        printf "\n%s:: Upgrade cancelled.%s\n" "$YELLOW" "$RESET"
        _yay_restore_channel "$old_gen" "$new_gen"
      fi

      rm -rf "$tmp_dir"
      ;;

    -h|--help)
      _yay_colors
      printf "%sFake yay wrapper for NixOS (Declarative)%s\n\n" "$BOLD" "$RESET"
      printf "  %syay -S <package...>%s   Add to user-packages.nix & rebuild (no upgrades)\n" "$CYAN" "$RESET"
      printf "  %syay -Ss <query>%s       Search Nixpkgs\n" "$CYAN" "$RESET"
      printf "  %syay -Si <package>%s     Show package information\n" "$CYAN" "$RESET"
      printf "  %syay -Q / -Qe%s          List declarative & imperative packages\n" "$CYAN" "$RESET"
      printf "  %syay -R <package...>%s   Remove from user-packages.nix & rebuild (no upgrades)\n" "$CYAN" "$RESET"
      printf "  %syay -Syu / -Syyu%s      Arch-style system upgrade with version diffs & size estimates\n\n" "$CYAN" "$RESET"
      printf "%sFeatures:%s\n" "$BOLD" "$RESET"
      printf "  * Smart package resolution for bare names, namespaces (%skdePackages.*%s, %sgnome.*%s, %spython3Packages.*%s)\n" "$CYAN" "$RESET" "$CYAN" "$RESET" "$CYAN" "$RESET"
      printf "  * Interactive provider menu when multiple packages match (%sdiscord%s, %sdiscord-ptb%s, %sdiscord-bin%s)\n" "$CYAN" "$RESET" "$CYAN" "$RESET" "$CYAN" "$RESET"
      printf "  * Upgrade diff with package versions & closure size preview via %snvd%s\n" "$CYAN" "$RESET"
      ;;

    *)
      printf "%serror:%s unsupported yay operation: %s\n" "$RED" "$RESET" "$1"
      printf "Run: yay --help\n"
      return 1
      ;;
  esac
}

pacman() {
  yay "$@"
}
