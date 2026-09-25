# Custom aliases for Fish
# Cheatsheet Management System Configuration

# Cheat sheets aliases - Required for the system to work
alias csnew='~/.cheatsheets/csnew'
alias csadd='~/.cheatsheets/csadd'
alias csedit='~/.cheatsheets/csedit'
alias csdel='~/.cheatsheets/csdel'
alias cshelp='~/.cheatsheets/cshelp'
alias csalias='~/.cheatsheets/csalias'

function rtmux
    source "$HOME/.config/fish/conf.d/aliases.fish"
end

function __cs_cheatsheet_icon
    switch (string lower -- $argv[1])
        case aliases
            printf '%s\n' '🔧'
        case django
            printf '%s\n' '🌐'
        case docker
            printf '%s\n' '🐳'
        case git
            printf '%s\n' '🔀'
        case google
            printf '%s\n' '🌐'
        case nvim nvichad
            printf '%s\n' '⌨️'
        case tmux
            printf '%s\n' '🪟'
        case warp
            printf '%s\n' '⚡'
        case '*'
            printf '%s\n' '📄'
    end
end

# Cheat sheets function - Global name, command, and description search
function csfind
    set cheat_dir "$HOME/.cheatsheets"
    set rich_python (brew --prefix rich-cli)/libexec/bin/python
    set field_separator (printf '\t')
    set header 'Nombre · Comando · Descripción · Enter abre · Esc cancela'
    set reload_command "$rich_python \"$cheat_dir/index_cheatsheets.py\" \"$cheat_dir\""

    set selected (
        $rich_python "$cheat_dir/index_cheatsheets.py" "$cheat_dir" --query '' |
            env SHELL=/bin/sh fzf \
                --disabled \
                --ignore-case \
                --delimiter="$field_separator" \
                --with-nth=2,4,5,6 \
                --height=70% \
                --layout=reverse \
                --style='full:rounded' \
                --margin='8%,12%' \
                --padding='1,2' \
                --border-label='  CHEATS SEARCH  ' \
                --input-label='  Buscar  ' \
                --list-label='  Resultados  ' \
                --preview-label='  Vista previa  ' \
                --prompt='⌕  ' \
                --header="$header" \
                --info=inline-right \
                --pointer='▶' \
                --marker='✓' \
                --scrollbar='│' \
                --color='bg:#1a1b26,bg+:#292e42,fg:#a9b1d6,fg+:#c0caf5,hl:#bb9af7,hl+:#bb9af7,info:#7aa2f7,prompt:#7aa2f7,pointer:#bb9af7,marker:#9ece6a,spinner:#e0af68,header:#565f89,border:#7aa2f7,label:#bb9af7,separator:#292e42,scrollbar:#565f89,preview-bg:#16161e,preview-border:#565f89' \
                --bind="start:reload:$reload_command --query {q}" \
                --bind="change:reload:$reload_command --query {q}" \
                --preview="$rich_python $cheat_dir/render_cheatsheet.py --no-pager {1}" \
                --preview-window='right:55%:wrap'
    )

    if test -n "$selected"
        set selected $selected[1]
        set file (string split \t -- $selected)[1]
        $rich_python "$cheat_dir/render_cheatsheet.py" --no-pager "$file" | less -R
    end
end

function __cs_select_cheatsheet
    set cheat_dir "$HOME/.cheatsheets"
    set rich_python (brew --prefix rich-cli)/libexec/bin/python
    set field_separator (printf '\t')
    set prompt $argv[1]
    set header $argv[2]

    if test -z "$prompt"
        set prompt '⌕ cheatsheets> '
    end
    if test -z "$header"
        set header 'Seleccioná un cheatsheet · Enter confirma · q/Esc cancela'
    end

    set selected (
        for file in "$cheat_dir"/*.md
            set filename (string replace -r '^.*/' '' -- "$file")
            if string match -q 'README*.md' -- "$filename"
                continue
            end
            set tool (string replace -r '\.md$' '' -- "$filename")
            printf '%s\t%s\t%s %s\n' "$file" "$tool" (__cs_cheatsheet_icon "$tool") "$tool"
        end |
            env SHELL=/bin/sh fzf \
                --ignore-case \
                --delimiter="$field_separator" \
                --with-nth=3 \
                --prompt="$prompt" \
                --header="$header" \
                --bind='q:abort' \
                --preview="$rich_python $cheat_dir/render_cheatsheet.py --no-pager {1}" \
                --preview-window='right:65%:wrap'
    )

    if test -n "$selected"
        set fields (string split \t -- $selected)
        printf '%s\n' "$fields[2]"
    end
end

# Cheat sheets function - Hub, selector, and direct viewer
function cs
    set cheat_dir "$HOME/.cheatsheets"
    set rich_python (brew --prefix rich-cli)/libexec/bin/python

    if test (count $argv) -eq 0
        while true
            set selected ($rich_python "$cheat_dir/cs_menu.py" "$cheat_dir")

            if test -z "$selected"
                return 0
            end

            set fields (string split \t -- $selected[1])
            if test "$fields[1]" = cheat
                $rich_python "$cheat_dir/render_cheatsheet.py" --no-pager "$fields[2]" | less -R
                continue
            end

            switch $fields[2]
                case new
                    printf '\n  cs > crear\n\n'
                    read -P 'Nombre del cheatsheet: ' tool
                    if string match -q -r '^[qQ]$' -- "$tool"
                        continue
                    end
                    if test -n "$tool"
                        "$cheat_dir/csnew" "$tool"
                    end
                case add edit delete
                    set tool (__cs_select_cheatsheet '⌕ destino> ' 'Seleccioná el cheatsheet a modificar')
                    if test -n "$tool"
                        set script_action $fields[2]
                        if test "$script_action" = delete
                            set script_action del
                        end
                        switch $fields[2]
                            case add
                                set action_label agregar
                            case edit
                                set action_label editar
                            case delete
                                set action_label eliminar
                        end
                        printf '\n  cs > %s > %s\n\n' "$action_label" "$tool"
                        "$cheat_dir/cs$script_action" "$tool"
                    end
                case alias
                    printf '\n  cs > alias\n\n'
                    "$cheat_dir/csalias"
                case find
                    csfind
                case help
                    "$cheat_dir/cshelp"
            end
            continue
        end
    end

    set tool $argv[1]
    set file "$cheat_dir/$tool.md"

    if test -f "$file"
        $rich_python "$cheat_dir/render_cheatsheet.py" "$file"
    else
        echo "❌ No encontré cheat sheet para '$tool'"
        echo "📝 Puedes crearlo con: csnew $tool"
        echo ""
        echo "📚 Disponibles:"
        for available_file in "$cheat_dir"/*.md
            set filename (string replace -r '^.*/' '' -- "$available_file")
            if string match -q 'README*.md' -- "$filename"
                continue
            end
            set available_tool (string replace -r '\.md$' '' -- "$filename")
            printf '  %s %s\n' (__cs_cheatsheet_icon "$available_tool") "$available_tool"
        end
    end
end

#ALIAS
alias v='nvim'
alias fzfbat='fzf --preview="bat --theme=gruvbox-dark --color=always {}"'
alias fzfnvim='nvim (fzf --preview="bat --theme=gruvbox-dark --color=always {}")'
alias avenv='source .venv/bin/activate.fish'
alias cvenv='python3 -m venv .venv'
alias ls='ls -la'
alias l1='tree -L 1'
alias l2='tree -L 2'
alias l3='tree -L 3'

alias l='lsd -l'
alias la='lsd -a'
alias lla='lsd -la'
alias lt='lsd --tree'

#GIT
function commit
    /Users/jalberth/Documents/customUtils/customsGIT.bash $argv
end

#SERVER
alias clinuxserver='ssh jserver'
alias cimacserver='ssh imac'
alias blockiserver='osascript -e \'tell application "System Events" to keystroke "q" using {control down, command down}\''

# PYTHON ALIAS
alias runserver='python3 manage.py runserver'
alias createsuperuser='python3 manage.py createsuperuser'
alias check='python3 manage.py check'
alias migrate='python3 manage.py makemigrations;python3 manage.py migrate'

#DOCKER ALIAS
alias dk='docker'
alias dkps='docker ps'
alias dkpsa='docker ps -a'
alias dkstart='docker start'
alias dkcdown='docker compose down'
alias dkcupd='docker compose up -d'
alias dkcupi='docker compose up -d -i'
alias dkcps='docker compose ps'
alias dkclog='docker compose logs -f'
alias dkcbuild='docker compose build'
alias dkfullcheck='docker compose down; docker compose up -d --build; docker compose exec backend uv run pytest; docker compose exec backend uv run ruff check . --fix; docker compose exec backend uv run ruff check .'
# Compatibility alias: repo help documents `cheat`, implementation uses `cs`.
function cheat
    cs $argv
end
