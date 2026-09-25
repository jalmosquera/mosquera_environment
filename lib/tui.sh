#!/usr/bin/env bash
# Interactive entrypoint for Mosquera Soft. Compatible with macOS Bash 3.2.

MOSQUERA_TUI_PROFILE="workstation"
MOSQUERA_TUI_SYSTEM=""
MOSQUERA_TUI_MANAGER=""
MOSQUERA_TUI_ARCH=""
MOSQUERA_TUI_SELECTION=0
MOSQUERA_TUI_ACTIVE=false

mosquera_tui_init() {
    MOSQUERA_TUI_SYSTEM="$(uname -s)"
    MOSQUERA_TUI_ARCH="$(uname -m)"
    case "$MOSQUERA_TUI_SYSTEM" in
        Darwin) MOSQUERA_TUI_SYSTEM='macOS'; MOSQUERA_TUI_MANAGER='Homebrew' ;;
        Linux)
            if command -v pacman >/dev/null 2>&1; then
                MOSQUERA_TUI_MANAGER='pacman'
            else
                MOSQUERA_TUI_MANAGER='apt'
            fi
            ;;
        *) MOSQUERA_TUI_MANAGER='unknown' ;;
    esac
    MOSQUERA_TUI_ACTIVE=true
    printf '\033[?25l'
    trap 'mosquera_tui_cleanup' EXIT
    trap 'mosquera_tui_exit 130' INT
    trap 'mosquera_tui_exit 143' TERM
    trap 'mosquera_tui_render_home' WINCH
}

mosquera_tui_cleanup() {
    "$MOSQUERA_TUI_ACTIVE" || return 0
    printf '\033[?25h\033[0m'
    MOSQUERA_TUI_ACTIVE=false
}

mosquera_tui_exit() {
    local code="$1"
    mosquera_tui_cleanup
    trap - EXIT INT TERM WINCH
    exit "$code"
}

mosquera_tui_width() {
    local width
    width="$(tput cols 2>/dev/null || printf 80)"
    [[ "$width" =~ ^[0-9]+$ ]] || width=80
    (( width >= 40 )) || width=40
    printf '%s' "$width"
}

mosquera_tui_center() {
    local text="$1" width padding
    width="$(mosquera_tui_width)"
    padding=$(( (width - ${#text}) / 2 ))
    (( padding > 0 )) || padding=0
    printf '%*s%s\n' "$padding" '' "$text"
}

mosquera_tui_color() {
    [[ -z "${NO_COLOR:-}" ]] && printf '\033[%sm' "$1"
}

mosquera_tui_reset() {
    [[ -z "${NO_COLOR:-}" ]] && printf '\033[0m'
}

mosquera_tui_clear() {
    printf '\033[2J\033[H'
}

mosquera_tui_header() {
    local width
    width="$(mosquera_tui_width)"
    printf '\n\n'
    if (( width >= 84 )); then
        mosquera_tui_color '1;33'
        mosquera_tui_center ' __  __  ___  ____   ___  _   _ _____ ____      _     ____   ___  _____ _____ '
        mosquera_tui_center '|  \/  |/ _ \/ ___| / _ \| | | | ____|  _ \    / \   / ___| / _ \|  ___|_   _|'
        mosquera_tui_center '| |\/| | | | \___ \| | | | | | |  _| | |_) |  / _ \  \___ \| | | | |_    | |  '
        mosquera_tui_center '| |  | | |_| |___) | |_| | |_| | |___|  _ <  / ___ \  ___) | |_| |  _|   | |  '
        mosquera_tui_center '|_|  |_|\___/|____/ \__\_\\___/|_____|_| \_\/_/   \_\|____/ \___/|_|     |_|  '
        mosquera_tui_reset
    else
        mosquera_tui_color '1;33'; mosquera_tui_center 'MOSQUERA SOFT'; mosquera_tui_reset
    fi
    mosquera_tui_color '2;36'; mosquera_tui_center 'Environment Installer'; mosquera_tui_reset
    printf '\n'
}

mosquera_tui_read_key() {
    local key rest
    IFS= read -r -s -n 1 key || return 1
    if [[ "$key" == $'\033' ]]; then
        if IFS= read -r -s -n 2 -t 0.05 rest; then
            case "$rest" in
                '[A') printf up ;;
                '[B') printf down ;;
                *) printf esc ;;
            esac
        else
            printf esc
        fi
    elif [[ "$key" == $'\n' || "$key" == $'\r' ]]; then
        printf enter
    else
        printf '%s' "$key"
    fi
}

mosquera_tui_menu_item() {
    local index="$1" key="$2" label="$3"
    if (( MOSQUERA_TUI_SELECTION == index )); then
        mosquera_tui_color '1;33'; mosquera_tui_center ">  $key    $label"; mosquera_tui_reset
    else
        mosquera_tui_center "   $key    $label"
    fi
}

mosquera_tui_render_home() {
    mosquera_tui_clear
    mosquera_tui_header
    mosquera_tui_color '1'; mosquera_tui_center 'Actions'; mosquera_tui_reset
    printf '\n'
    mosquera_tui_menu_item 0 i Install
    mosquera_tui_menu_item 1 d 'Dry Run'
    mosquera_tui_menu_item 2 p 'Select Profile'
    mosquera_tui_menu_item 3 c 'Check System'
    mosquera_tui_menu_item 4 h Help
    mosquera_tui_menu_item 5 q Quit
    printf '\n\n'
    mosquera_tui_color '2'; mosquera_tui_center "Profile    $MOSQUERA_TUI_PROFILE"; mosquera_tui_center "Platform   $MOSQUERA_TUI_SYSTEM $MOSQUERA_TUI_ARCH"; mosquera_tui_center "Package    $MOSQUERA_TUI_MANAGER"; mosquera_tui_reset
    printf '\n'
    mosquera_tui_color '2'; mosquera_tui_center 'j/k or arrows navigate  |  Enter select  |  shortcut keys work anywhere'; mosquera_tui_reset
}

mosquera_tui_profile_description() {
    case "$1" in
        core) printf 'Terminal and essential environment' ;;
        server) printf 'Headless server environment' ;;
        workstation) printf 'Complete development workstation' ;;
        full) printf 'Workstation plus graphical integrations' ;;
    esac
}

mosquera_tui_profile_screen() {
    local profiles=(core server workstation full) selected=0 key item
    for key in 0 1 2 3; do [[ "${profiles[$key]}" == "$MOSQUERA_TUI_PROFILE" ]] && selected="$key"; done
    while true; do
        mosquera_tui_clear; mosquera_tui_header
        mosquera_tui_color '1'; mosquera_tui_center 'Select Profile'; mosquera_tui_reset
        printf '\n'
        for key in 0 1 2 3; do
            item="${profiles[$key]}"
            if (( key == selected )); then mosquera_tui_color '1;33'; mosquera_tui_center ">  $item"; mosquera_tui_reset; else mosquera_tui_center "   $item"; fi
            mosquera_tui_color '2'; mosquera_tui_center "   $(mosquera_tui_profile_description "$item")"; mosquera_tui_reset
            printf '\n'
        done
        mosquera_tui_color '2'; mosquera_tui_center 'arrows/j/k navigate  |  Enter select  |  Esc back'; mosquera_tui_reset
        case "$(mosquera_tui_read_key)" in
            up|k) selected=$(( (selected + 3) % 4 )) ;;
            down|j) selected=$(( (selected + 1) % 4 )) ;;
            enter) MOSQUERA_TUI_PROFILE="${profiles[$selected]}"; return ;;
            esc|q) return ;;
        esac
    done
}

mosquera_tui_wait_back() {
    while true; do
        case "$(mosquera_tui_read_key)" in esc|q|enter) return ;; esac
    done
}

mosquera_tui_help_screen() {
    mosquera_tui_clear; mosquera_tui_header
    mosquera_tui_color '1'; mosquera_tui_center 'Help'; mosquera_tui_reset
    printf '\n'
    mosquera_tui_center 'i  Install after confirmation'
    mosquera_tui_center 'd  Run a non-destructive dry run after confirmation'
    mosquera_tui_center 'p  Select a session profile without installing'
    mosquera_tui_center 'c  Check platform and prerequisites only'
    mosquera_tui_center 'Doctor and Update remain available as ./doctor and ./update'
    printf '\n'; mosquera_tui_color '2'; mosquera_tui_center 'Esc or q to return'; mosquera_tui_reset
    mosquera_tui_wait_back
}

mosquera_tui_confirm_screen() {
    local mode="$1" prompt
    [[ "$mode" == dry-run ]] && prompt='Start Dry Run' || prompt='Start Installation'
    while true; do
        mosquera_tui_clear; mosquera_tui_header
        mosquera_tui_color '1;33'; mosquera_tui_center "${mode//-/ }"; mosquera_tui_reset
        printf '\n'
        mosquera_tui_center "Profile    $MOSQUERA_TUI_PROFILE"
        mosquera_tui_center "Platform   $MOSQUERA_TUI_SYSTEM $MOSQUERA_TUI_ARCH"
        mosquera_tui_center "Package    $MOSQUERA_TUI_MANAGER"
        printf '\n'
        if [[ "$mode" == dry-run ]]; then
            mosquera_tui_center 'No system changes will be made.'
        else
            mosquera_tui_center 'Mosquera Soft will verify, install, configure and validate this environment.'
        fi
        printf '\n\n'; mosquera_tui_color '1'; mosquera_tui_center "Enter  $prompt"; mosquera_tui_reset; mosquera_tui_color '2'; mosquera_tui_center 'Esc  Cancel'; mosquera_tui_reset
        case "$(mosquera_tui_read_key)" in enter) return 0 ;; esc|q) return 1 ;; esac
    done
}

mosquera_tui_check_system() {
    local check_result=0 output
    mosquera_tui_clear; mosquera_tui_header
    mosquera_tui_color '1'; mosquera_tui_center 'System Check'; mosquera_tui_reset
    printf '\n'
    output="$(MOSQUERA_TUI_CHECK_ONLY=true MOSQUERA_TUI_SUPPRESS_UI=true "$ROOT_DIR/install" "$MOSQUERA_TUI_PROFILE" --check-system 2>&1)" || check_result=$?
    if (( check_result == 0 )); then
        mosquera_tui_center '+  Platform and architecture'
        mosquera_tui_center '+  Package manager'
        mosquera_tui_center '+  Git and curl'
        mosquera_tui_center '+  Network access'
        mosquera_tui_center '+  Home directory and disk space'
    else
        mosquera_tui_color '1;31'; mosquera_tui_center "${output##*$'\n'}"; mosquera_tui_reset
    fi
    printf '\n'
    if (( check_result == 0 )); then mosquera_tui_color '1;32'; mosquera_tui_center 'System ready.'; mosquera_tui_reset; else mosquera_tui_color '1;31'; mosquera_tui_center 'System check failed.'; mosquera_tui_reset; fi
    printf '\n'; mosquera_tui_color '2'; mosquera_tui_center 'Esc or q to return'; mosquera_tui_reset
    mosquera_tui_wait_back
}

mosquera_tui_result_screen() {
    local result="$1" log="${2:-}" title message key
    while true; do
        mosquera_tui_clear; mosquera_tui_header
        if [[ "$result" == success ]]; then
            mosquera_tui_color '1;32'; title='READY'; message="$MOSQUERA_TUI_PROFILE environment installed successfully"; mosquera_tui_center "+  $title"; mosquera_tui_reset
        elif [[ "$result" == dry-run ]]; then
            mosquera_tui_color '1;33'; title='DRY RUN COMPLETE'; message='No changes were made.'; mosquera_tui_center "$title"; mosquera_tui_reset
        else
            mosquera_tui_color '1;31'; title='FAILED'; message='Installation failed. Review the log before retrying.'; mosquera_tui_center "x  $title"; mosquera_tui_reset
        fi
        printf '\n'; mosquera_tui_center "$message"
        [[ -n "$log" ]] && { printf '\n'; mosquera_tui_color '2'; mosquera_tui_center "Log  $log"; mosquera_tui_reset; }
        printf '\n\n'
        if [[ "$result" == success ]]; then mosquera_tui_center 'd  Run Doctor'; fi
        [[ -n "$log" ]] && mosquera_tui_center 'l  View Log'
        mosquera_tui_center 'q  Exit'
        key="$(mosquera_tui_read_key)"
        case "$key" in
            d) [[ "$result" == success ]] && "$ROOT_DIR/doctor" --profile "$MOSQUERA_TUI_PROFILE"; mosquera_tui_wait_back ;;
            l) [[ -n "$log" ]] && { mosquera_tui_cleanup; less "$log"; MOSQUERA_TUI_ACTIVE=true; printf '\033[?25l'; } ;;
            q|esc|enter) return ;;
        esac
    done
}

mosquera_tui_run_engine() {
    local mode="$1" exit_code log
    MOSQUERA_TUI_ACTIVE=false
    printf '\033[2J\033[H\033[?25h'
    if [[ "$mode" == dry-run ]]; then
        TERM=dumb "$ROOT_DIR/install" "$MOSQUERA_TUI_PROFILE" --dry-run
        exit_code=$?
    else
        TERM=dumb "$ROOT_DIR/install" "$MOSQUERA_TUI_PROFILE"
        exit_code=$?
    fi
    log="$(ls -t "${XDG_STATE_HOME:-$HOME/.local/state}/mosquera-soft/logs/install-"*.log 2>/dev/null | head -1 || true)"
    MOSQUERA_TUI_ACTIVE=true
    printf '\033[?25l'
    if (( exit_code == 0 )); then
        [[ "$mode" == dry-run ]] && mosquera_tui_result_screen dry-run "$log" || mosquera_tui_result_screen success "$log"
    else
        mosquera_tui_result_screen failed "$log"
    fi
}

mosquera_tui_automated_demo() {
    local mode="$1"
    mosquera_tui_init
    case "$mode" in
        home) mosquera_tui_render_home ;;
        profile) mosquera_tui_profile_screen ;;
        check) mosquera_tui_check_system ;;
        dry-run) mosquera_tui_run_engine dry-run ;;
    esac
    mosquera_tui_cleanup
}

mosquera_tui_main() {
    mosquera_tui_init
    while true; do
        mosquera_tui_render_home
        case "$(mosquera_tui_read_key)" in
            up|k) MOSQUERA_TUI_SELECTION=$(( (MOSQUERA_TUI_SELECTION + 5) % 6 )) ;;
            down|j) MOSQUERA_TUI_SELECTION=$(( (MOSQUERA_TUI_SELECTION + 1) % 6 )) ;;
            i) MOSQUERA_TUI_SELECTION=0; mosquera_tui_confirm_screen install && mosquera_tui_run_engine install ;;
            d) MOSQUERA_TUI_SELECTION=1; mosquera_tui_confirm_screen dry-run && mosquera_tui_run_engine dry-run ;;
            p) MOSQUERA_TUI_SELECTION=2; mosquera_tui_profile_screen ;;
            c) MOSQUERA_TUI_SELECTION=3; mosquera_tui_check_system ;;
            h) MOSQUERA_TUI_SELECTION=4; mosquera_tui_help_screen ;;
            q|esc) mosquera_tui_exit 0 ;;
            enter)
                case "$MOSQUERA_TUI_SELECTION" in
                    0) mosquera_tui_confirm_screen install && mosquera_tui_run_engine install ;;
                    1) mosquera_tui_confirm_screen dry-run && mosquera_tui_run_engine dry-run ;;
                    2) mosquera_tui_profile_screen ;;
                    3) mosquera_tui_check_system ;;
                    4) mosquera_tui_help_screen ;;
                    5) mosquera_tui_exit 0 ;;
                esac
                ;;
        esac
    done
}
