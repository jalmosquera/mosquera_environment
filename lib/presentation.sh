#!/usr/bin/env bash
# Shared presentation and command logging for Mosquera Soft scripts.

MOSQUERA_UI_OPERATION="${MOSQUERA_UI_OPERATION:-}"
MOSQUERA_UI_INTERACTIVE=false
MOSQUERA_UI_VERBOSE=false
MOSQUERA_UI_DRY_RUN=false
MOSQUERA_UI_LOG_FILE=""
MOSQUERA_UI_CURRENT=""

mosquera_ui_init() {
    local operation="$1"
    local verbose="${2:-false}"
    local dry_run="${3:-false}"
    local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/mosquera-soft/logs"

    MOSQUERA_UI_OPERATION="$operation"
    MOSQUERA_UI_VERBOSE="$verbose"
    MOSQUERA_UI_DRY_RUN="$dry_run"
    if [[ -t 1 && -z "${CI:-}" && "${TERM:-dumb}" != dumb && "${NO_COLOR:-}" == "" ]]; then
        MOSQUERA_UI_INTERACTIVE=true
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

mosquera_ui_banner() {
    local system="$1" arch="$2" manager="$3" profile="${4:-n/a}"
    if "$MOSQUERA_UI_INTERACTIVE"; then
        printf '\033[1;36mMOSQUERA SOFT\033[0m  \033[2m%s\033[0m\n' "$MOSQUERA_UI_OPERATION"
        printf 'System      %s %s\nPackage     %s\nProfile     %s\n' "$system" "$arch" "$manager" "$profile"
    else
        printf 'MOSQUERA SOFT | %s | %s %s | %s | profile: %s\n' "$MOSQUERA_UI_OPERATION" "$system" "$arch" "$manager" "$profile"
    fi
    "$MOSQUERA_UI_DRY_RUN" && printf 'DRY RUN: no changes will be made.\n'
    printf '\n'
}

mosquera_ui_section() {
    printf '\n%s\n' "$1"
}

mosquera_ui_status() {
    local state="$1" label="$2" detail="$3"
    local tag
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
    if "$MOSQUERA_UI_INTERACTIVE"; then
        printf '%-9s %-20s %s\n' "[$tag]" "$label" "$detail"
    else
        printf '[%s] %s - %s\n' "$tag" "$label" "$detail"
    fi
    mosquera_ui_log "[$tag] $label - $detail"
}

mosquera_ui_note() {
    local detail="$*"
    printf '%s\n' "$detail"
    mosquera_ui_log "[NOTE] $detail"
}

mosquera_ui_progress() {
    local completed="$1" total="$2" label="$3" percent filled empty bar
    (( total > 0 )) || return 0
    percent=$(( completed * 100 / total ))
    if "$MOSQUERA_UI_INTERACTIVE"; then
        filled=$(( percent * 20 / 100 ))
        empty=$(( 20 - filled ))
        printf -v bar '%*s' "$filled" ''
        bar="${bar// /#}"
        printf -v empty '%*s' "$empty" ''
        empty="${empty// /-}"
        printf 'Progress    [%s%s] %3d%%  %s\n' "$bar" "$empty" "$percent" "$label"
    else
        printf '[PROGRESS] %d/%d (%d%%) - %s\n' "$completed" "$total" "$percent" "$label"
    fi
}

mosquera_ui_command() {
    local label="$1"
    shift
    local exit_code
    mosquera_ui_log "COMMAND [$label] $(printf '%q ' "$@")"
    if "$MOSQUERA_UI_DRY_RUN"; then
        mosquera_ui_status skip "$label" "would run: $(printf '%q ' "$@")"
        return 0
    fi
    if "$MOSQUERA_UI_VERBOSE"; then
        "$@" 2>&1 | tee -a "$MOSQUERA_UI_LOG_FILE"
        exit_code=${PIPESTATUS[0]}
    else
        "$@" >> "$MOSQUERA_UI_LOG_FILE" 2>&1
        exit_code=$?
    fi
    if (( exit_code != 0 )); then
        mosquera_ui_status fail "$label" "command failed (exit $exit_code)"
        printf 'Command: '
        printf '%q ' "$@"
        printf '\n'
        if [[ -n "$MOSQUERA_UI_LOG_FILE" && -r "$MOSQUERA_UI_LOG_FILE" ]]; then
            printf 'Log: %s\n' "$MOSQUERA_UI_LOG_FILE"
            printf '%s\n' 'Last output:'
            tail -n 40 "$MOSQUERA_UI_LOG_FILE" >&2
        fi
        return "$exit_code"
    fi
}

mosquera_ui_log_path() {
    [[ -n "$MOSQUERA_UI_LOG_FILE" ]] && printf '%s' "$MOSQUERA_UI_LOG_FILE"
}
