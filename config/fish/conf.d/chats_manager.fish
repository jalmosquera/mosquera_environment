# Load Chats Manager's machine-local integration without writing generated state here.
if set -q XDG_STATE_HOME
    set -l chats_manager_state_dir "$XDG_STATE_HOME/chats-manager/fish"
else
    set -l chats_manager_state_dir "$HOME/.local/state/chats-manager/fish"
end
set -l chats_manager_bootstrap "$chats_manager_state_dir/cheats_manager.fish"

if test -f "$chats_manager_bootstrap"
    source "$chats_manager_bootstrap"
end
