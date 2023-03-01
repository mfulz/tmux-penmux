#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/shared.sh"

start_pipe_pane() {
    local file=$(expand_tmux_format_path "${la_log_full_filename}")
    "$CURRENT_DIR/start_logging.sh" "${file}"
    display_message "Started logging to ${la_log_full_filename}"
}

stop_pipe_pane() {
    if use_script; then
        tmux send-keys " exit" Enter
    else
        tmux pipe-pane
    fi
    display_message "Ended logging to $la_log_full_filename"
}

# returns a string unique to current pane
pane_unique_id() {
    tmux display-message -p "#{session_name}-#{window_name}-#{pane_id}"
}

# saving 'logging' 'not logging' status in a variable unique to pane
set_logging_variable() {
    local value="$1"
    local pane_unique_id="$(pane_unique_id)"
    tmux set-option -gq "@${pane_unique_id}" "$value"
}

# this function checks if logging is happening for the current pane
is_logging() {
    local pane_unique_id="$(pane_unique_id)"
    local current_pane_logging="$(get_tmux_option "@${pane_unique_id}" "not logging")"
    if [ "$current_pane_logging" == "logging" ]; then
        return 0
    else
        return 1
    fi
}

store_pane_title() {
    local pane_unique_id="$(pane_unique_id)"
    local pane_title="$(tmux display-message -p "#{pane_title}")"
    tmux set-option -gq "@${pane_unique_id}-title" "${pane_title}"
}

set_pane_title() {
    local value="${1}"
    local pane_title="$(tmux display-message -p "#{pane_title}")"
    tmux select-pane -T "${pane_title}${value}"
}

restore_pane_title() {
    local pane_unique_id="$(pane_unique_id)"
    local pane_title="$(get_tmux_option "@${pane_unique_id}-title")"
    tmux select-pane -T "${pane_title}"
}

# starts/stop logging
toggle_pipe_pane() {
    if is_logging; then
        set_logging_variable "not logging"
        restore_pane_title
        stop_pipe_pane
    else
        set_logging_variable "logging"
        start_pipe_pane
        store_pane_title
        set_pane_title " *logging*"
    fi
}

# stop logging
main_stop() {
    if is_logging; then
        set_logging_variable "not logging"
        restore_pane_title
        stop_pipe_pane
    fi
}

main() {
    local ARG="${1}"

    if supported_tmux_version_ok; then
        if [[ ${ARG} == "stop" ]]; then
            main_stop
        else
            toggle_pipe_pane
        fi
    fi
}
main "$@"
