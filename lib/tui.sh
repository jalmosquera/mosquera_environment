#!/usr/bin/env bash
# Interactive entrypoint for Mosquera Soft. Compatible with macOS Bash 3.2.

MOSQUERA_TUI_PROFILE="workstation"
MOSQUERA_TUI_SYSTEM=""
MOSQUERA_TUI_MANAGER=""
MOSQUERA_TUI_ARCH=""
MOSQUERA_TUI_SELECTION=0
MOSQUERA_TUI_ACTIVE=false
readonly MOSQUERA_TUI_BANNER_WIDTH=112
readonly MOSQUERA_TUI_BANNER_MARGIN=2
MOSQUERA_TUI_WIDTH_SOURCE='fallback'
MOSQUERA_TUI_LAYOUT_CENTER=0

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
    local width tmux_width stty_size
    if [[ -n "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
        tmux_width="$(tmux display-message -p '#{pane_width}' 2>/dev/null || true)"
        if [[ "$tmux_width" =~ ^[1-9][0-9]*$ ]]; then
            MOSQUERA_TUI_WIDTH_SOURCE='tmux'
            printf '%s' "$tmux_width"
            return
        fi
    fi
    stty_size="$(stty size < /dev/tty 2>/dev/null || true)"
    width="${stty_size##* }"
    if [[ "$width" =~ ^[1-9][0-9]*$ ]]; then
        MOSQUERA_TUI_WIDTH_SOURCE='stty'
        printf '%s' "$width"
        return
    fi
    width="$(tput cols 2>/dev/null || true)"
    if [[ "$width" =~ ^[1-9][0-9]*$ ]]; then
        MOSQUERA_TUI_WIDTH_SOURCE='tput'
        printf '%s' "$width"
        return
    fi
    width="${COLUMNS:-}"
    if [[ "$width" =~ ^[1-9][0-9]*$ ]]; then
        MOSQUERA_TUI_WIDTH_SOURCE='COLUMNS'
        printf '%s' "$width"
        return
    fi
    MOSQUERA_TUI_WIDTH_SOURCE='fallback'
    width=80
    (( width >= 40 )) || width=40
    printf '%s' "$width"
}

mosquera_tui_center() {
    local text="$1" width padding
    width="$(mosquera_tui_width)"
    mosquera_tui_layout_center "$width"
    padding=$(( MOSQUERA_TUI_LAYOUT_CENTER - ${#text} / 2 ))
    (( padding > 0 )) || padding=0
    printf '%*s%s\n' "$padding" '' "$text"
}

mosquera_tui_layout_center() {
    local width="$1" offset
    offset=$(( width / 18 ))
    (( offset > 12 )) && offset=12
    MOSQUERA_TUI_LAYOUT_CENTER=$(( width / 2 + offset ))
}

mosquera_tui_block_line() {
    local text="$1" block_width="$2" width padding
    width="$(mosquera_tui_width)"
    mosquera_tui_layout_center "$width"
    padding=$(( MOSQUERA_TUI_LAYOUT_CENTER - block_width / 2 ))
    (( padding > 0 )) || padding=0
    printf '%*s%s\n' "$padding" '' "$text"
}

mosquera_tui_banner_fits() {
    local width="$1"
    (( width >= MOSQUERA_TUI_BANNER_WIDTH + MOSQUERA_TUI_BANNER_MARGIN ))
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
    if mosquera_tui_banner_fits "$width"; then
        mosquera_tui_color '1;33'
        mosquera_tui_center '███╗   ███╗ ██████╗ ███████╗ ██████╗ ██╗   ██╗███████╗██████╗  █████╗   ███████╗ ██████╗ ███████╗████████╗'
        mosquera_tui_center '████╗ ████║██╔═══██╗██╔════╝██╔═══██╗██║   ██║██╔════╝██╔══██╗██╔══██╗  ██╔════╝██╔═══██╗██╔════╝╚══██╔══╝'
        mosquera_tui_center '██╔████╔██║██║   ██║███████╗██║   ██║██║   ██║█████╗  ██████╔╝███████║  ███████╗██║   ██║█████╗     ██║'
        mosquera_tui_center '██║╚██╔╝██║██║   ██║╚════██║██║▄▄ ██║██║   ██║██╔══╝  ██╔══██╗██╔══██║  ╚════██║██║   ██║██╔══╝     ██║'
        mosquera_tui_center '██║ ╚═╝ ██║╚██████╔╝███████║╚██████╔╝╚██████╔╝███████╗██║  ██║██║  ██║  ███████║╚██████╔╝██║        ██║'
        mosquera_tui_center '╚═╝     ╚═╝ ╚═════╝ ╚══════╝ ╚══▀▀═╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝  ╚══════╝ ╚═════╝ ╚═╝        ╚═╝'
        mosquera_tui_reset
    else
        mosquera_tui_color '1;33'; mosquera_tui_center 'MOSQUERA SOFT'; mosquera_tui_reset
    fi
    mosquera_tui_color '2;36'; mosquera_tui_center 'Environment'; mosquera_tui_reset
    printf '\n'
}

mosquera_tui_read_key() {
    local key rest terminal_mode
    terminal_mode="$(stty -g < /dev/tty)" || return 1
    stty -icanon -echo min 1 time 0 < /dev/tty || {
        stty "$terminal_mode" < /dev/tty
        return 1
    }
    if ! IFS= read -r -n 1 key < /dev/tty; then
        stty "$terminal_mode" < /dev/tty
        [[ -z "$key" ]] && printf enter
        return
    fi
    stty "$terminal_mode" < /dev/tty

    if [[ -z "$key" ]]; then
        printf enter
        return 0
    fi
    if [[ "$key" == $'\033' ]]; then
        if IFS= read -r -s -n 2 -t 1 rest < /dev/tty; then
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
    local index="$1" key="$2" label="$3" block_width="${4:-38}" marker=' '
    (( MOSQUERA_TUI_SELECTION == index )) && marker='>'
    if (( MOSQUERA_TUI_SELECTION == index )); then
        mosquera_tui_color '1;33'; mosquera_tui_block_line "$marker  $key   $label" "$block_width"; mosquera_tui_reset
    else
        mosquera_tui_block_line "$marker  $key   $label" "$block_width"
    fi
}

mosquera_tui_render_home() {
    local width block_width=38
    mosquera_tui_clear
    mosquera_tui_header
    width="$(mosquera_tui_width)"
    mosquera_tui_layout_center "$width"
    printf '\n\n'
    mosquera_tui_color '1'; mosquera_tui_block_line 'Acciones' "$block_width"; mosquera_tui_reset
    printf '\n'
    mosquera_tui_menu_item 0 i Instalar "$block_width"
    mosquera_tui_menu_item 1 d Simulación "$block_width"
    mosquera_tui_menu_item 2 p 'Seleccionar perfil' "$block_width"
    mosquera_tui_menu_item 3 c 'Comprobar sistema' "$block_width"
    mosquera_tui_menu_item 4 h Ayuda "$block_width"
    mosquera_tui_menu_item 5 q Salir "$block_width"
    printf '\n\n'
    mosquera_tui_color '2'
    mosquera_tui_block_line "Perfil       $MOSQUERA_TUI_PROFILE" "$block_width"
    mosquera_tui_block_line "Plataforma   $MOSQUERA_TUI_SYSTEM $MOSQUERA_TUI_ARCH" "$block_width"
    mosquera_tui_block_line "Gestor       $MOSQUERA_TUI_MANAGER" "$block_width"
    mosquera_tui_reset
    printf '\n\n'
    mosquera_tui_color '2'; mosquera_tui_block_line 'j/k o flechas para navegar  |  Enter para seleccionar' "$block_width"; mosquera_tui_reset
}

mosquera_tui_profile_description() {
    case "$1" in
        core) printf 'Terminal y entorno esencial' ;;
        server) printf 'Entorno para servidores sin interfaz gráfica' ;;
        workstation) printf 'Estación completa de desarrollo' ;;
        full) printf 'Estación de trabajo e integraciones gráficas' ;;
    esac
}

mosquera_tui_profile_screen() {
    local profiles=(core server workstation full) selected=0 key item
    for key in 0 1 2 3; do [[ "${profiles[$key]}" == "$MOSQUERA_TUI_PROFILE" ]] && selected="$key"; done
    while true; do
        mosquera_tui_clear; mosquera_tui_header
        mosquera_tui_color '1'; mosquera_tui_center 'Seleccionar perfil'; mosquera_tui_reset
        printf '\n'
        for key in 0 1 2 3; do
            item="${profiles[$key]}"
            if (( key == selected )); then mosquera_tui_color '1;33'; mosquera_tui_center ">  $item"; mosquera_tui_reset; else mosquera_tui_center "   $item"; fi
            mosquera_tui_color '2'; mosquera_tui_center "   $(mosquera_tui_profile_description "$item")"; mosquera_tui_reset
            printf '\n'
        done
        mosquera_tui_color '2'; mosquera_tui_center 'flechas/j/k para navegar  |  Enter para seleccionar  |  Esc para volver'; mosquera_tui_reset
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
    mosquera_tui_color '1'; mosquera_tui_center 'Ayuda'; mosquera_tui_reset
    printf '\n'
    mosquera_tui_center 'i  Instalar después de confirmar'
    mosquera_tui_center 'd  Ejecutar una simulación no destructiva'
    mosquera_tui_center 'p  Elegir un perfil para esta sesión sin instalar'
    mosquera_tui_center 'c  Comprobar plataforma y requisitos'
    mosquera_tui_center 'Doctor y Update siguen disponibles como ./doctor y ./update'
    printf '\n'; mosquera_tui_color '2'; mosquera_tui_center 'Esc o q para volver'; mosquera_tui_reset
    mosquera_tui_wait_back
}

mosquera_tui_confirm_screen() {
    local mode="$1" prompt
    [[ "$mode" == dry-run ]] && prompt='Iniciar simulación' || prompt='Iniciar instalación'
    while true; do
        mosquera_tui_clear; mosquera_tui_header
        if [[ "$mode" == dry-run ]]; then
            mosquera_tui_color '1;33'; mosquera_tui_center 'Simulación'; mosquera_tui_reset
        else
            mosquera_tui_color '1;33'; mosquera_tui_center 'Listo para instalar'; mosquera_tui_reset
        fi
        printf '\n'
        mosquera_tui_center "Perfil       $MOSQUERA_TUI_PROFILE"
        mosquera_tui_center "Plataforma   $MOSQUERA_TUI_SYSTEM $MOSQUERA_TUI_ARCH"
        mosquera_tui_center "Gestor       $MOSQUERA_TUI_MANAGER"
        printf '\n'
        if [[ "$mode" == dry-run ]]; then
            mosquera_tui_center 'No se realizarán cambios en el sistema.'
        else
            mosquera_tui_center 'Mosquera Soft verificará, instalará, configurará y validará este entorno.'
        fi
        printf '\n\n'; mosquera_tui_color '1'; mosquera_tui_center "Intro  $prompt"; mosquera_tui_reset; mosquera_tui_color '2'; mosquera_tui_center 'Esc  Cancelar'; mosquera_tui_reset
        case "$(mosquera_tui_read_key)" in enter) return 0 ;; esc|q) return 1 ;; esac
    done
}

mosquera_tui_check_system() {
    local check_result=0 output
    mosquera_tui_clear; mosquera_tui_header
    mosquera_tui_color '1'; mosquera_tui_center 'Comprobación del sistema'; mosquera_tui_reset
    printf '\n'
    output="$(MOSQUERA_TUI_CHECK_ONLY=true MOSQUERA_TUI_SUPPRESS_UI=true "$ROOT_DIR/install" "$MOSQUERA_TUI_PROFILE" --check-system 2>&1)" || check_result=$?
    if (( check_result == 0 )); then
        mosquera_tui_center '+  Plataforma y arquitectura'
        mosquera_tui_center '+  Gestor de paquetes'
        mosquera_tui_center '+  Git y curl'
        mosquera_tui_center '+  Acceso de red'
        mosquera_tui_center '+  Directorio personal y espacio disponible'
    else
        mosquera_tui_color '1;31'; mosquera_tui_center "${output##*$'\n'}"; mosquera_tui_reset
    fi
    printf '\n'
    if (( check_result == 0 )); then mosquera_tui_color '1;32'; mosquera_tui_center 'Sistema listo.'; mosquera_tui_reset; else mosquera_tui_color '1;31'; mosquera_tui_center 'La comprobación falló.'; mosquera_tui_reset; fi
    printf '\n'; mosquera_tui_color '2'; mosquera_tui_center 'Esc o q para volver'; mosquera_tui_reset
    mosquera_tui_wait_back
}

mosquera_tui_result_screen() {
    local result="$1" log="${2:-}" title message key
    while true; do
        mosquera_tui_clear; mosquera_tui_header
        if [[ "$result" == success ]]; then
            mosquera_tui_color '1;32'; title='LISTO'; message="Entorno $MOSQUERA_TUI_PROFILE instalado correctamente"; mosquera_tui_center "+  $title"; mosquera_tui_reset
        elif [[ "$result" == dry-run ]]; then
            mosquera_tui_color '1;33'; title='SIMULACIÓN COMPLETADA'; message='No se realizaron cambios.'; mosquera_tui_center "$title"; mosquera_tui_reset
        else
            mosquera_tui_color '1;31'; title='FALLÓ'; message='La instalación falló. Revisá el registro antes de reintentar.'; mosquera_tui_center "x  $title"; mosquera_tui_reset
        fi
        printf '\n'; mosquera_tui_center "$message"
        [[ -n "$log" ]] && { printf '\n'; mosquera_tui_color '2'; mosquera_tui_center "Registro  $log"; mosquera_tui_reset; }
        printf '\n\n'
        if [[ "$result" == success ]]; then mosquera_tui_center 'd  Ejecutar Doctor'; fi
        [[ -n "$log" ]] && mosquera_tui_center 'l  Ver registro'
        mosquera_tui_center 'q  Salir'
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
