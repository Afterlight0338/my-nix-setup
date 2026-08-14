# /etc/nixos/roxy-palette.nix
# Centralized Roxy Migurdia Palette - Single Source of Truth
# Character reference: Roxy Migurdia (Mushoku Tensei: Jobless Reincarnation)

rec {
  # Dark charcoal foundation & surfaces
  background      = "#171A24"; # Dark charcoal base
  surface         = "#232735"; # Surface cards / panels / containers
  surface_alt     = "#303548"; # Elevated / alternative surface

  # Cream / Off-white text & muted labels
  foreground      = "#E7E5E0"; # Cream readable text
  muted           = "#A9A9B5"; # Muted text / secondary labels

  # Roxy Blue identity
  primary         = "#6687C7"; # Roxy blue main identity
  primary_bright  = "#8FA9E0"; # Roxy blue bright / active

  # Cool magical / icy blue highlight
  accent          = "#72B9E8"; # Icy blue accent

  # Cloak / Earth & Muted Gold accents
  brown           = "#8A6B56"; # Warm brown / taupe cloak
  tan             = "#C5A47A"; # Muted tan accent
  gold            = "#C7A15A"; # Warm gold accent

  # UI Structural & Selection
  border          = "#46516B"; # Subdued border outline
  selection       = "#405B91"; # Soft selection background

  # Utility helpers for color formatting across downstream apps
  # Removes leading '#' for engines requiring raw hex (e.g. Hyprland / Qt colors)
  stripHash = hex: if builtins.substring 0 1 hex == "#" then builtins.substring 1 6 hex else hex;
}
