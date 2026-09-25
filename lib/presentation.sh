#!/usr/bin/env bash
# Shared presentation and command logging for Mosquera Soft scripts.

MOSQUERA_UI_OPERATION="${MOSQUERA_UI_OPERATION:-}"
MOSQUERA_UI_INTERACTIVE=false
MOSQUERA_UI_VERBOSE=false
MOSQUERA_UI_DRY_RUN=false
MOSQUERA_UI_LOG_FILE=""
MOSQUERA_UI_CURRENT=""
MOSQUERA_UI_DASHBOARD=false
MOSQUERA_UI_RENDERED_LINES=0
MOSQUERA_UI_TOTAL=0
MOSQUERA_UI_COMPLETED=0
MOSQUERA_UI_ACTIVE_SECTION=""
MOSQUERA_UI_STATUS_MESSAGE=""
MOSQUERA_UI_SPINNER_INDEX=0
MOSQUERA_UI_CURSOR_HIDDEN=false
MOSQUERA_UI_COLOR=false
declare -a MOSQUERA_UI_ITEMS=()
declare MOSQUERA_UI_ITEM_STATE=""
declare MOSQUERA_UI_ITEM_DETAIL=""
declare MOSQUERA_UI_SECTION_STATE=""

mosquera_ui_key() {
    printf '%s' "$1" | tr -c '[:alnum:]_' '_'
}

mosquera_ui_title() {
    case "$1" in
        chatsManager) printf 'chatsManager' ;;
        *) printf '%s' "$1" | awk '{ print toupper(substr($0, 1, 1)) substr($0, 2) }' ;;
    esac
}

mosquera_ui_init() {
    local operation="$1" verbose="${2:-false}" dry_run="${3:-false}"
    local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/mosquera-soft/logs"

    MOSQUERA_UI_OPERATION="$operation"
    MOSQUERA_UI_VERBOSE="$verbose"
    MOSQUERA_UI_DRY_RUN="$dry_run"
    if [[ -t 1 && -z "${CI:-}" && "${TERM:-dumb}" != dumb && "$verbose" != true ]]; then
        MOSQUERA_UI_INTERACTIVE=true
        MOSQUERA_UI_DASHBOARD=true
        [[ -z "${NO_COLOR:-}" ]] && MOSQUERA_UI_COLOR=true
        trap 'mosquera_ui_cleanup' EXIT
        trap 'mosquera_ui_interrupt 130' INT
        trap 'mosquera_ui_interrupt 143' TERM
    fi
    if mkdir -p "$state_dir" 2>/dev/null; then
        MOSQUERA_UI_LOG_FILE="$state_dir/${operation}-$(date +%Y%m%d-%H%M%S)-$$.log"
        : > "$MOSQUERA_UI_LOG_FILE"
    fi
}

mosquera_ui_log() {
    [[ -n "$MOSQUERA_UI_LOG_FILE" ]] || return 0
    printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*" >> "$MOSQUERA_UI_LOG_FILE"
}

mosquera_ui_style() {
    local code="$1"
    "$MOSQUERA_UI_COLOR" && printf '\033[%sm' "$code"
}

mosquera_ui_reset() {
    "$MOSQUERA_UI_COLOR" && printf '\033[0m'
}

mosquera_ui_terminal_width() {
    local width
    width="$(tput cols 2>/dev/null || printf '80')"
    [[ "$width" =~ ^[0-9]+$ ]] || width=80
    (( width >= 40 )) || width=40
    printf '%s' "$width"
}

mosquera_ui_repeat() {
    local character="$1" count="$2"
    (( count > 0 )) || return 0
    printf '%*s' "$count" '' | tr ' ' "$character"
}

mosquera_ui_cleanup() {
    if "$MOSQUERA_UI_CURSOR_HIDDEN"; then
        printf '\033[?25h'
        MOSQUERA_UI_CURSOR_HIDDEN=false
    fi
    mosquera_ui_reset
}

mosquera_ui_interrupt() {
    local exit_code="$1"
    mosquera_ui_cleanup
    printf '\nInterrupted.\n' >&2
    trap - EXIT INT TERM
    exit "$exit_code"
}

mosquera_ui_clear_dashboard() {
    local line
    (( MOSQUERA_UI_RENDERED_LINES > 0 )) || return 0
    printf '\033[%dA' "$MOSQUERA_UI_RENDERED_LINES"
    for ((line = 0; line < MOSQUERA_UI_RENDERED_LINES; line++)); do
        printf '\r\033[2K\n'
    done
    printf '\033[%dA' "$MOSQUERA_UI_RENDERED_LINES"
}

mosquera_ui_trim() {
    local value="$1" limit="$2"
    if (( ${#value} > limit )); then
        printf '%s...' "${value:0:limit-3}"
    else
        printf '%s' "$value"
    fi
}

mosquera_ui_state_icon() {
    case "$1" in
        pending) printf 'o' ;;
        checking|installing) printf '%s' "${2:-*}" ;;
        already-installed|installed|updated|ok) printf '+' ;;
        skipped) printf '-' ;;
        failed) printf 'x' ;;
        *) printf '-' ;;
    esac
}

mosquera_ui_state_text() {
    case "$1" in
        pending) printf 'pending' ;;
        checking) printf 'checking...' ;;
        installing) printf 'installing...' ;;
        already-installed) printf 'already installed' ;;
        installed) printf 'installed' ;;
        updated) printf 'updated' ;;
        skipped) printf 'skipped' ;;
        failed) printf 'failed' ;;
        *) printf '%s' "$1" ;;
    esac
}

mosquera_ui_dashboard_start() {
    local total="$1"
    shift
    MOSQUERA_UI_TOTAL="$total"
    MOSQUERA_UI_COMPLETED=0
    MOSQUERA_UI_ITEMS=()
    local item
    for item in "$@"; do
        [[ -n "$item" ]] || continue
        MOSQUERA_UI_ITEMS+=("$item")
        local key
        key="$(mosquera_ui_key "$item")"
        printf -v "MOSQUERA_UI_ITEM_STATE_$key" '%s' pending
        printf -v "MOSQUERA_UI_ITEM_DETAIL_$key" '%s' pending
    done
    MOSQUERA_UI_SECTION_STATE_preflight=ok
    MOSQUERA_UI_SECTION_STATE_dependencies=checking
    MOSQUERA_UI_SECTION_STATE_configuration=pending
    MOSQUERA_UI_SECTION_STATE_chatsManager=pending
    MOSQUERA_UI_SECTION_STATE_verification=pending
    MOSQUERA_UI_ACTIVE_SECTION=dependencies
    MOSQUERA_UI_STATUS_MESSAGE='Checking dependencies...'
    if "$MOSQUERA_UI_DASHBOARD"; then
        printf '\033[?25l'
        MOSQUERA_UI_CURSOR_HIDDEN=true
        mosquera_ui_render_dashboard
    fi
}

mosquera_ui_set_section() {
    local section="$1" state="${2:-checking}"
    MOSQUERA_UI_ACTIVE_SECTION="$section"
    printf -v "MOSQUERA_UI_SECTION_STATE_$section" '%s' "$state"
    mosquera_ui_render_dashboard
}

mosquera_ui_complete_section() {
    local section="$1" detail="${2:-passed}"
    printf -v "MOSQUERA_UI_SECTION_STATE_$section" '%s' ok
    MOSQUERA_UI_STATUS_MESSAGE="$section: $detail"
    mosquera_ui_render_dashboard
}

mosquera_ui_set_item() {
    local item="$1" state="$2" detail="${3:-}"
    local key
    key="$(mosquera_ui_key "$item")"
    printf -v "MOSQUERA_UI_ITEM_STATE_$key" '%s' "$state"
    printf -v "MOSQUERA_UI_ITEM_DETAIL_$key" '%s' "${detail:-$(mosquera_ui_state_text "$state")}"
    MOSQUERA_UI_CURRENT="$item"
    MOSQUERA_UI_STATUS_MESSAGE="$(mosquera_ui_state_text "$state") $(mosquera_ui_trim "$item" 28)"
    mosquera_ui_render_dashboard
}

mosquera_ui_complete_item() {
    local item="$1" state="$2" detail="${3:-}"
    mosquera_ui_set_item "$item" "$state" "$detail"
    MOSQUERA_UI_COMPLETED=$((MOSQUERA_UI_COMPLETED + 1))
    mosquera_ui_render_dashboard
}

mosquera_ui_spinner_tick() {
    MOSQUERA_UI_SPINNER_INDEX=$(( (MOSQUERA_UI_SPINNER_INDEX + 1) % 4 ))
    mosquera_ui_render_dashboard
}

mosquera_ui_render_dashboard() {
    "$MOSQUERA_UI_DASHBOARD" || return 0
    local width content_width label_width bar_width percent filled empty item state detail icon spinner section state_icon line_count=0
    local -a spinner_frames=('|' '/' '-' '\\')
    width="$(mosquera_ui_terminal_width)"
    content_width=$(( width - 4 ))
    (( content_width > 36 )) || content_width=36
    label_width=22
    (( width < 68 )) && label_width=16
    bar_width=$(( width - 31 ))
    (( bar_width > 30 )) && bar_width=30
    (( bar_width < 12 )) && bar_width=12
    percent=0
    (( MOSQUERA_UI_TOTAL > 0 )) && percent=$(( MOSQUERA_UI_COMPLETED * 100 / MOSQUERA_UI_TOTAL ))
    filled=$(( percent * bar_width / 100 ))
    empty=$(( bar_width - filled ))
    spinner="${spinner_frames[MOSQUERA_UI_SPINNER_INDEX]}"

    mosquera_ui_clear_dashboard
    if (( width >= 64 )); then
        mosquera_ui_style '1;33'; printf '+%s+\n' "$(mosquera_ui_repeat '-' "$content_width")"; mosquera_ui_reset; line_count=$((line_count + 1))
        printf '|'; printf '%*s' $(( (content_width + 13) / 2 )) '' | tr ' ' ' '; mosquera_ui_style '1;33'; printf 'MOSQUERA SOFT'; mosquera_ui_reset; printf '%*s|\n' $(( (content_width - 13) / 2 )) ''; line_count=$((line_count + 1))
        printf '|'; printf '%*s' $(( (content_width + 21) / 2 )) ''; printf 'Environment Installer'; printf '%*s|\n' $(( (content_width - 21) / 2 )) ''; line_count=$((line_count + 1))
        mosquera_ui_style '1;33'; printf '+%s+\n' "$(mosquera_ui_repeat '-' "$content_width")"; mosquera_ui_reset; line_count=$((line_count + 1))
    else
        mosquera_ui_style '1;33'; printf 'MOSQUERA SOFT'; mosquera_ui_reset; printf '  Environment Installer\n'; line_count=$((line_count + 1))
    fi
    printf '  %s | %s | %s' "${MOSQUERA_UI_SYSTEM:-system}" "${MOSQUERA_UI_MANAGER:-manager}" "${MOSQUERA_UI_PROFILE:-profile}"
    "$MOSQUERA_UI_DRY_RUN" && { mosquera_ui_style '1;33'; printf ' | DRY RUN'; mosquera_ui_reset; }
    printf '\n\n'; line_count=$((line_count + 2))

    for section in preflight dependencies configuration chatsManager verification; do
        eval "state=\${MOSQUERA_UI_SECTION_STATE_$section:-pending}"
        state_icon="$(mosquera_ui_state_icon "$state" "$spinner")"
        if [[ "$section" == "$MOSQUERA_UI_ACTIVE_SECTION" ]]; then
            mosquera_ui_style '1;33'; printf '  %s %s\n' "$state_icon" "$(mosquera_ui_title "$section")"; mosquera_ui_reset
            line_count=$((line_count + 1))
            if [[ "$section" == dependencies ]]; then
                for item in "${MOSQUERA_UI_ITEMS[@]-}"; do
                    [[ -n "$item" ]] || continue
                    local key
                    key="$(mosquera_ui_key "$item")"
                    eval "state=\${MOSQUERA_UI_ITEM_STATE_$key:-pending}"
                    eval "detail=\${MOSQUERA_UI_ITEM_DETAIL_$key:-pending}"
                    icon="$(mosquera_ui_state_icon "$state" "$spinner")"
                    printf '    %-2s %-*s %s\n' "$icon" "$label_width" "$(mosquera_ui_trim "$item" "$label_width")" "$(mosquera_ui_trim "$detail" $((width - label_width - 9)))"
                    line_count=$((line_count + 1))
                done
            fi
        else
            printf '  %s %s\n' "$state_icon" "$(mosquera_ui_title "$section")"
            line_count=$((line_count + 1))
        fi
    done
    printf '\n  Overall  ['; mosquera_ui_style '1;33'; printf '%s' "$(mosquera_ui_repeat '#' "$filled")"; mosquera_ui_reset; printf '%s] %3d%%\n' "$(mosquera_ui_repeat '-' "$empty")" "$percent"
    printf '  %s %s\n' "$spinner" "$(mosquera_ui_trim "$MOSQUERA_UI_STATUS_MESSAGE" $((width - 4)))"
    line_count=$((line_count + 3))
    MOSQUERA_UI_RENDERED_LINES="$line_count"
}

mosquera_ui_finish_dashboard() {
    "$MOSQUERA_UI_DASHBOARD" || return 0
    mosquera_ui_render_dashboard
    printf '\n'
    MOSQUERA_UI_RENDERED_LINES=0
    mosquera_ui_cleanup
}

mosquera_ui_banner() {
    local system="$1" arch="$2" manager="$3" profile="${4:-n/a}"
    MOSQUERA_UI_SYSTEM="$system $arch"
    MOSQUERA_UI_MANAGER="$manager"
    MOSQUERA_UI_PROFILE="$profile"
    if "$MOSQUERA_UI_DASHBOARD"; then
        return 0
    fi
    printf 'MOSQUERA SOFT | %s | %s %s | %s | profile: %s\n' "$MOSQUERA_UI_OPERATION" "$system" "$arch" "$manager" "$profile"
    "$MOSQUERA_UI_DRY_RUN" && printf 'DRY RUN: no changes will be made.\n'
    printf '\n'
}

mosquera_ui_section() {
    local section="$1"
    if "$MOSQUERA_UI_DASHBOARD"; then
        case "$section" in
            Preflight) mosquera_ui_set_section preflight checking ;;
            Dependencies) mosquera_ui_set_section dependencies checking ;;
            Configuration) mosquera_ui_set_section configuration checking ;;
            chatsManager) mosquera_ui_set_section chatsManager checking ;;
            Verification) mosquera_ui_set_section verification checking ;;
        esac
    else
        printf '\n%s\n' "$section"
    fi
}

mosquera_ui_status() {
    local state="$1" label="$2" detail="$3" tag
    case "$state" in
        ok) tag='OK' ;;
        install) tag='INSTALL' ;;
        update) tag='UPDATE' ;;
        skip) tag='SKIP' ;;
        warn) tag='WARN' ;;
        fail) tag='FAIL' ;;
        info) tag='INFO' ;;
        *) tag="$state" ;;
    esac
    if "$MOSQUERA_UI_DASHBOARD"; then
        [[ "$state" == fail ]] && mosquera_ui_finish_dashboard
        mosquera_ui_log "[$tag] $label - $detail"
        return 0
    fi
    printf '[%s] %s - %s\n' "$tag" "$label" "$detail"
    mosquera_ui_log "[$tag] $label - $detail"
}

mosquera_ui_note() {
    local detail="$*"
    if ! "$MOSQUERA_UI_DASHBOARD"; then
        printf '%s\n' "$detail"
    fi
    mosquera_ui_log "[NOTE] $detail"
}

mosquera_ui_progress() {
    local completed="$1" total="$2" label="$3"
    MOSQUERA_UI_COMPLETED="$completed"
    MOSQUERA_UI_TOTAL="$total"
    MOSQUERA_UI_STATUS_MESSAGE="Completed $(mosquera_ui_trim "$label" 28)"
    if "$MOSQUERA_UI_DASHBOARD"; then
        mosquera_ui_render_dashboard
    else
        printf '[PROGRESS] %d/%d (%d%%) - %s\n' "$completed" "$total" "$((completed * 100 / total))" "$label"
    fi
}

mosquera_ui_command() {
    local label="$1"
    shift
    local exit_code
    mosquera_ui_log "COMMAND [$label] $(printf '%q ' "$@")"
    if "$MOSQUERA_UI_DRY_RUN"; then
        if "$MOSQUERA_UI_VERBOSE"; then
            mosquera_ui_status skip "$label" "would run: $(printf '%q ' "$@")"
        fi
        return 0
    fi
    if "$MOSQUERA_UI_VERBOSE"; then
        "$@" 2>&1 | tee -a "$MOSQUERA_UI_LOG_FILE"
        exit_code=${PIPESTATUS[0]}
    else
        if "$MOSQUERA_UI_DASHBOARD"; then
            "$@" >> "$MOSQUERA_UI_LOG_FILE" 2>&1 &
            local pid=$!
            while kill -0 "$pid" 2>/dev/null; do
                sleep 0.12
                mosquera_ui_spinner_tick
            done
            wait "$pid"
            exit_code=$?
        else
            "$@" >> "$MOSQUERA_UI_LOG_FILE" 2>&1
            exit_code=$?
        fi
    fi
    if (( exit_code != 0 )); then
        mosquera_ui_status fail "$label" "command failed (exit $exit_code)"
        printf 'Command: '
        printf '%q ' "$@"
        printf '\nLog: %s\nLast output:\n' "$MOSQUERA_UI_LOG_FILE"
        tail -n 40 "$MOSQUERA_UI_LOG_FILE" >&2
        return "$exit_code"
    fi
}

mosquera_ui_log_path() {
    [[ -n "$MOSQUERA_UI_LOG_FILE" ]] && printf '%s' "$MOSQUERA_UI_LOG_FILE"
}
