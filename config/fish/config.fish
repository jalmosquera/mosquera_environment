if status is-interactive
    if type -q brew
        eval (brew shellenv)
    end

    set -gx PATH $HOME/.local/bin $HOME/.atuin/bin $HOME/.opencode/bin $HOME/.volta/bin $HOME/.bun/bin $HOME/.cargo/bin $PATH

    if type -q starship
        starship init fish | source
    end
    if type -q zoxide
        zoxide init fish | source
    end
    if type -q atuin
        atuin init fish | source
    end
    if type -q fzf; and fzf --help | string match -q '*--fish*'
        fzf --fish | source
    end
    if type -q carapace
        set -gx CARAPACE_BRIDGES 'zsh,fish,bash'
        carapace _carapace | source
    end

    # Opt in per machine with `set -Ux MOSQUERA_AUTO_TMUX 1`.
    if set -q MOSQUERA_AUTO_TMUX; and not set -q TMUX; and type -q tmux
        tmux new-session -A -s main
    end
end

if test -r "$HOME/.config/fish/mosquera.local.fish"
    source "$HOME/.config/fish/mosquera.local.fish"
end

set -g fish_greeting ""

# Enable vi mode without persisting a universal variable in fish_variables.
set -g fish_key_bindings fish_vi_key_bindings

# Set nvim as default editor for opencode and other tools
set -gx EDITOR nvim
set -gx VISUAL nvim

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
