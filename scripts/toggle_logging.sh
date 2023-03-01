#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/shared.sh"

start_pipe_pane() {
    local PANE_ID="${1}"
    local file=$(expand_tmux_format_path "${la_log_full_filename}")
    "$CURRENT_DIR/start_logging.sh" "${PANE_ID}" "${file}"
    display_message2 "${PANE_ID}" "Started logging to ${la_log_full_filename}"
}

stop_pipe_pane() {
    local PANE_ID="${1}"
    if use_script; then
        tmux send-keys -t "${PANE_ID}" " exit" Enter
    else
        tmux pipe-pane -t "${PANE_ID}"
    fi
    display_message2 "${PANE_ID}" "Ended logging to $la_log_full_filename"
}

# saving 'logging' 'not logging' status in a variable unique to pane
set_logging_variable() {
    local PANE_ID="${1}"
    local value="${2}"
    tmux set-option -gq "@${PANE_ID}" "$value"
}

# this function checks if logging is happening for the current pane
is_logging() {
    local PANE_ID="${1}"
    local current_pane_logging="$(get_tmux_option "@${PANE_ID}" "not logging")"
    if [ "$current_pane_logging" == "logging" ]; then
        return 0
    else
        return 1
    fi
}

store_pane_title() {
    local PANE_ID="${1}"
    local pane_title="$(tmux display-message -t "${PANE_ID}" -p "#{pane_title}")"
    tmux set-option -gq "@${PANE_ID}-title" "${pane_title}"
}

set_pane_title() {
    local PANE_ID="${1}"
    local value="${2}"
    local pane_title="$(tmux display-message -t "${PANE_ID}" -p "#{pane_title}")"
    tmux select-pane -t "${PANE_ID}" -T "${pane_title}${value}"
}

restore_pane_title() {
    local PANE_ID="${1}"
    local pane_title="$(get_tmux_option "@${PANE_ID}-title")"
    tmux select-pane -t "${PANE_ID}" -T "${pane_title}"
}

# starts/stop logging
toggle_pipe_pane() {
    local PANE_ID="${1}"

    if is_logging "${PANE_ID}"; then
        set_logging_variable "${PANE_ID}" "not logging"
        restore_pane_title "${PANE_ID}"
        stop_pipe_pane "${PANE_ID}"
    else
        set_logging_variable "${PANE_ID}" "logging"
        start_pipe_pane "${PANE_ID}"
        store_pane_title "${PANE_ID}"
        set_pane_title "${PANE_ID}" " *logging*"
    fi
}

# toggle logging
toggle_log() {
    local PANE_ID="${1}"

    if is_logging "${PANE_ID}"; then
        stop_pipe "${PANE_ID}"
    else
        start_pipe "${PANE_ID}"
    fi
}

# start logging
start_log() {
    local PANE_ID="${1}"

    if is_logging "${PANE_ID}"; then
        return 0
    fi
    echo "START"

    set_logging_variable "${PANE_ID}" "logging"
    store_pane_title "${PANE_ID}"
    set_pane_title "${PANE_ID}" " *logging*"
    start_pipe_pane "${PANE_ID}"
}

# stop logging
stop_log() {
    local PANE_ID="${1}"

    if ! is_logging "${PANE_ID}"; then
        return 0
    fi
    echo "STOP"

    stop_pipe_pane "${PANE_ID}"
    set_logging_variable "${PANE_ID}" "not logging"
    restore_pane_title "${PANE_ID}"
}

main() {
    local ACTION="toggle"
    local PANE_ID="$(tmux display-message -p "#{pane_id}")"

    local OPTIND o
    while getopts "a:p:" o; do
        case "${o}" in
            a)
                ACTION="${OPTARG}"
                ;;
            p)
                PANE_ID="${OPTARG}"
                ;;
            *)
                echo >&2 "Invalid parameter"
                exit 1
                ;;
        esac
    done

    if supported_tmux_version_ok; then
        case "${ACTION}" in
            "start")
                start_log "${PANE_ID}"
                ;;
            "stop")
                stop_log "${PANE_ID}"
                ;;
            "toggle")
                toggle_log "${PANE_ID}"
                ;;
            *)
                echo >&2 "Invalid action '${ACTION}'"
                exit 1
                ;;
        esac
    fi

    if supported_tmux_version_ok; then
        if [[ ${ARG} == "stop" ]]; then
            main_stop
        else
            toggle_pipe_pane "${PANE_ID}"
        fi
    fi
}
main "$@"
