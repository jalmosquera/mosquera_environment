if status is-interactive
    # Commands to run in interactive sessions can go here
    # Install Fisher if not installed
    if not functions -q fisher
        curl -sL https://git.io/fisher | source

    end

end

# Detect Termux
set -l IS_TERMUX 0
if test -n "$TERMUX_VERSION"; or test -d /data/data/com.termux
    set IS_TERMUX 1
end

if test $IS_TERMUX -eq 1
    # Termux - use PREFIX for binaries
    set -x PATH $PREFIX/bin $HOME/.local/bin $HOME/.cargo/bin $PATH
else if test (uname) = Darwin
    # macOS - check for Apple Silicon vs Intel
    if test -f /opt/homebrew/bin/brew
        # Apple Silicon (M1/M2/M3)
        set BREW_BIN /opt/homebrew/bin/brew
    else if test -f /usr/local/bin/brew
        # Intel Mac
        set BREW_BIN /usr/local/bin/brew
    end
    set -x PATH $HOME/.local/bin $HOME/.opencode/bin $HOME/.volta/bin $HOME/.bun/bin $HOME/.nix-profile/bin /nix/var/nix/profiles/default/bin /usr/local/bin $HOME/.config $HOME/.cargo/bin $PATH
else
    # Linux
    set BREW_BIN /home/linuxbrew/.linuxbrew/bin/brew
    set -x PATH $HOME/.local/bin $HOME/.opencode/bin $HOME/.volta/bin $HOME/.bun/bin $HOME/.nix-profile/bin /nix/var/nix/profiles/default/bin /usr/local/bin $HOME/.config $HOME/.cargo/bin $PATH
end

# Only eval brew shellenv if brew is installed (not on Termux)
if test $IS_TERMUX -eq 0; and set -q BREW_BIN; and test -f $BREW_BIN
    eval ($BREW_BIN shellenv)
end

# Start tmux/zellij
if not set -q TMUX
    tmux
end

#if not set -q ZELLIJ
#    zellij
#end

# Initialize tools
starship init fish | source
zoxide init fish | source
atuin init fish | source
fzf --fish | source

set -x PATH $HOME/.cargo/bin $PATH

# Carapace completions
set -Ux CARAPACE_BRIDGES 'zsh,fish,bash'

if not test -d ~/.config/fish/completions
    mkdir -p ~/.config/fish/completions
end

if not test -f ~/.config/fish/completions/.initialized
    if not test -d ~/.config/fish/completions
        mkdir -p ~/.config/fish/completions
    end
    carapace --list | awk '{print $1}' | xargs -I{} touch ~/.config/fish/completions/{}.fish
    touch ~/.config/fish/completions/.initialized
end

carapace _carapace fish | source

set -g fish_greeting ""

# Enable vi mode
fish_vi_key_bindings

# Set nvim as default editor for opencode and other tools
set -gx EDITOR nvim
set -gx VISUAL nvim

## alias
if test (uname) = Darwin
    alias ls='ls --color=auto'
else
    alias ls='gls --color=auto'
end

set -l foreground C0CAF5 normal
set -l selection 28344A
set -l comment 565F89 brblack
set -l red F7768E red
set -l orange FF9E64 brred
set -l yellow E0AF68 yellow
set -l green 9ECE6A green
set -l purple BB9AF7 brmagenta
set -l cyan 7DCFFF brcyan
set -l pink F7768E brred

# Syntax Highlighting Colors
set -g fish_color_normal $foreground
set -g fish_color_command $cyan
set -g fish_color_keyword $pink
set -g fish_color_quote $yellow
set -g fish_color_redirection $foreground
set -g fish_color_end $orange
set -g fish_color_error $red
set -g fish_color_param $purple
set -g fish_color_comment $comment
set -g fish_color_selection --background=$selection
set -g fish_color_search_match --background=$selection
set -g fish_color_operator $green
set -g fish_color_escape $pink
set -g fish_color_autosuggestion $comment

# Completion Pager Colors
set -g fish_pager_color_progress $comment
set -g fish_pager_color_prefix $cyan
set -g fish_pager_color_completion $foreground
set -g fish_pager_color_description $comment
clear

# opencode
fish_add_path /Users/jalberth/.opencode/bin

# Hermes Agent — ensure ~/.local/bin is on PATH
fish_add_path "$HOME/.local/bin"
