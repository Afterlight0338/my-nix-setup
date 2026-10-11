# Terminal colors from the current Caelestia scheme (new shells follow >scheme changes)
if [[ -r ~/.local/state/caelestia/scheme.json ]]; then
    jq -r '.colours | "10;#\(.onSurface)", "11;#\(.background)", "12;#\(.primary)", "17;#\(.surfaceContainerHigh)",
        (range(16) as $i | "4;\($i);#\(.["term\($i)"])")' ~/.local/state/caelestia/scheme.json |
        while read -r s; do printf '\e]%s\e\\' "$s"; done
fi
# Prompt (grimoire frame): ╭─✦ user@host  path  branch / ╰─❯ ; the ❯ turns red and the exit code
# shows on the right after a failed command, commands that took 3s+ show their time on the right
autoload -Uz vcs_info add-zsh-hook
zmodload zsh/datetime
setopt prompt_subst
zstyle ':vcs_info:git:*' formats '  %F{10} %b%f'
zstyle ':vcs_info:git:*' actionformats '  %F{10} %b%f %F{9}(%a)%f'
_prompt_preexec() { _cmd_start=$EPOCHSECONDS }
_prompt_precmd() {
    vcs_info
    RPROMPT='%(?..%F{9}✗ %?%f)'
    if [[ -n $_cmd_start ]]; then
        (( EPOCHSECONDS - _cmd_start >= 3 )) && RPROMPT+=" %F{7}$(( EPOCHSECONDS - _cmd_start ))s%f"
        unset _cmd_start
    fi
}
add-zsh-hook preexec _prompt_preexec
add-zsh-hook precmd _prompt_precmd
PROMPT=$'%F{12}╭─%f%F{11}✦%f %B%F{12}%n%f%F{7}@%f%F{14}%m%f%b  %F{11}%~%f${vcs_info_msg_0_}\n%F{12}╰─%f%B%(?.%F{12}.%F{9})❯%f%b '

# eza: colours + icons for ls
alias ls='eza --icons=auto --group-directories-first'
alias ll='eza -l --icons=auto --group-directories-first --git'
alias la='eza -la --icons=auto --group-directories-first --git'
alias tree='eza --tree --icons=auto'
# Only greet with fastfetch in big windows; small tiles just get a prompt
fastfetch_greet=1  # Rice Settings edits this line
(( fastfetch_greet && COLUMNS >= 90 && LINES >= 24 )) && fastfetch
source ~/.config/zsh/yay-nix.zsh

export PATH="$HOME/.local/bin:$PATH"


# Suggestions from history as you type (→ or End accepts) and live command colouring.
# Colours are terminal palette numbers, so they follow the Caelestia scheme. Rice Settings edits the two flags.
zsh_autosuggest=1
zsh_highlight=1
if (( zsh_autosuggest )) && [[ -r ~/.nix-profile/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    source ~/.nix-profile/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
# Must stay the last thing sourced in this file
if (( zsh_highlight )) && [[ -r ~/.nix-profile/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source ~/.nix-profile/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    ZSH_HIGHLIGHT_STYLES[command]='fg=12'
    ZSH_HIGHLIGHT_STYLES[builtin]='fg=12'
    ZSH_HIGHLIGHT_STYLES[function]='fg=12'
    ZSH_HIGHLIGHT_STYLES[alias]='fg=14'
    ZSH_HIGHLIGHT_STYLES[precommand]='fg=14,italic'
    ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=13'
    ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=9'
    ZSH_HIGHLIGHT_STYLES[path]='underline'
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=11'
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=11'
    ZSH_HIGHLIGHT_STYLES[comment]='fg=8,italic'
fi
