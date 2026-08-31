{ config, pkgs, lib, ... }:

let
  cfg = config.custom.system.smartGc;
in
{
  options.custom.system.smartGc = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable smart GC preserving last 3 generations and deleting older than 14d";
    };
  };

  config = lib.mkIf cfg.enable {
    # Custom GC Service: Keeps current + 2 previous generations regardless of age;
    # deletes older generations only if created > 14 days ago.
    systemd.services.nixos-smart-gc = {
      description = "NixOS Smart Garbage Collection (preserve last 3 generations, delete older than 14d)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "nixos-smart-gc" ''
          set -euo pipefail
          now=$(${pkgs.coreutils}/bin/date +%s)
          cutoff=$((now - 14 * 86400))
          
          # Collect system generation symlinks sorted by version number
          links=($(${pkgs.coreutils}/bin/ls -d /nix/var/nix/profiles/system-*-link 2>/dev/null | ${pkgs.coreutils}/bin/sort -V || true))
          total=''${#links[@]}
          
          if [ "$total" -gt 3 ]; then
            candidate_count=$((total - 3))
            candidates=("''${links[@]:0:$candidate_count}")
            
            to_delete=()
            for link in "''${candidates[@]}"; do
              mtime=$(${pkgs.coreutils}/bin/stat -c %Y "$link" 2>/dev/null || echo "$now")
              if [ "$mtime" -lt "$cutoff" ]; then
                gen=$(${pkgs.coreutils}/bin/basename "$link" | ${pkgs.gnused}/bin/sed -E 's/system-([0-9]+)-link/\1/')
                to_delete+=("$gen")
              fi
            done
            
            if [ "''${#to_delete[@]}" -gt 0 ]; then
              echo "Deleting generations older than 14 days: ''${to_delete[*]}"
              ${pkgs.nix}/bin/nix-env -p /nix/var/nix/profiles/system --delete-generations "''${to_delete[@]}"
            fi
          fi
          
          # Collect unreferenced store garbage and deduplicate
          ${pkgs.nix}/bin/nix-collect-garbage
          ${pkgs.nix}/bin/nix-store --optimise
        '';
      };
    };

    systemd.timers.nixos-smart-gc = {
      description = "Weekly Smart Garbage Collection";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };
  };
}
