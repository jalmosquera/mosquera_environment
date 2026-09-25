# General aliases. chatsManager installs its own Fish integration.
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
