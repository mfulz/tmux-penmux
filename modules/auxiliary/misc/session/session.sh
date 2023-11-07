#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PENMUX_SCRIPTS=""
_MODULE_PATH=""

source "$CURRENT_DIR/shared.sh"

_update_default_command() {
  local pane_id="$1"
  local default_command="$(get_tmux_option "default-command" "" "$pane_id")"
  local last_default_command
  local session_name="$(get_tmux_option "@penmux-session-name" "" "$pane_id")"
  local session_dir="$(get_tmux_option "@penmux-session-dir" "" "$pane_id")"
  local session_ready="$(get_tmux_option "@penmux-session-ready" "" "$pane_id")"
  local session="$(tmux display-message -p "#S")"

  if [[ "$default_command" != "\"$CURRENT_DIR/session.sh\" -a init -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\" -n \"$session_name\" -d \"$session_dir\"" ]]; then
    if [ -n "$session_dir" ]; then
      if [[ "$default_command" != "\"$CURRENT_DIR/session.sh\""* ]]; then
        tmux set-option -t "$session" "@penmux-session-default-command" "$default_command"
      fi
      tmux set-option -t "$session" default-command "\"$CURRENT_DIR/session.sh\" -a init -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\" -n \"$session_name\" -d \"$session_dir\""
    fi
  else
    if [ -z "$session_dir" ]; then
      last_default_command="$(get_tmux_option "@penmux-session-default-command" "" "$pane_id")"
      tmux set-option -t "$session" default-command "$last_default_command"
    fi
  fi
}

_new() {
  local pane_id="$1"
  local session_name="$(tmux command-prompt -p "Session Name: " "display-message -p '%%'")"
  local session_dir="$(_get_new_session_dir "$pane_id" "$session_name")"

  if [ ! -d "$session_dir" ]; then
    err="$(mkdir -p "$session_dir" >/dev/null)" || {
    echo "Unable to create session dir: '$session_dir' ('$err')"
      exit 1
    }
  fi 

  if [ ! -e "$session_dir/$session_name.pmses" ]; then
    err="$(touch "$session_dir/$session_name.pmses" >/dev/null)" || {
    echo "Unable to create session file: '$session_dir/$session_name.pmses' ('$err')"
      exit 1
    }
  fi

  unset_tmux_hook "after-set-option" "$CURRENT_DIR/session.sh" "$session"
  tmux set-option -p -t "$pane_id" "@penmux-session-name" "$session_name"
  tmux set-hook -t "$session" -a after-set-option "run-shell '\"$CURRENT_DIR/session.sh\" -a reload -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"
  tmux send-keys -t "$pane_id" " cd $session_dir" Enter
  tmux set-option -p -t "$pane_id" "@penmux-session-dir" "$session_dir"
  # tmux set-option -p -t "$pane_id" "@penmux-session-ready" "1"
}

_stop() {
  local pane_id="$1"
  local session="$(tmux display-message -p "#S")"
  local last_default_command="$(get_tmux_option "@penmux-session-default-command" "" "$pane_id")"
 
  if [ -n "$last_default_command" ]; then
    tmux set-option -t "$session" default-command "$last_default_command"
  else
    tmux set-option -t "$session" -u default-command
  fi

  tmux set-option -t "$session" -u "@penmux-session-default-command" "$last_default_command"
  tmux set-option -p -t "$pane_id" -u "@penmux-session-name"
  tmux set-option -p -t "$pane_id" -u "@penmux-session-dir"
}

_reload() {
  local pane_id="$1"
  local session_name="$(get_tmux_option "@penmux-session-name" "" "$pane_id")"
  local session_dir="$(get_tmux_option "@penmux-session-dir" "" "$pane_id")"
  local window_name="$(tmux display-message -p "#W")"

  unset_tmux_hook "after-set-option" "$CURRENT_DIR/session.sh" "$session"
  _update_default_command "$pane_id"
  tmux set-hook -t "$session" -a after-set-option "run-shell '\"$CURRENT_DIR/session.sh\" -a reload -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"

  if [ -z "$session_dir" ]; then
    if [[ "$window_name" != "No Ses" ]]; then
      tmux rename-window "No Ses"
    fi
  else
    tmux rename-window "$session_name"
  fi
}

_init() {
  local pane_id="$1"
  local session_name="$2"
  local session_dir="$3"
  local session="$(tmux display-message -p "#S")"
  local last_default_command="$(get_tmux_option "@penmux-session-default-command" "" "$pane_id")"

  if [ -z "$last_default_command" ]; then
    last_default_command="$SHELL"
  fi

  unset_tmux_hook "after-set-option" "$CURRENT_DIR/session.sh" "$session"
  tmux set-option -t "$pane_id" -p "@penmux-session-name" "$session_name"
  tmux set-option -t "$pane_id" -p "@penmux-session-dir" "$session_dir"
  # tmux set-option -t "$pane_id" -p "@penmux-session-ready" "1"

  # dirty hack for window ready
  sleep 1
  if [ -z "$session_dir" ]; then
    if [[ "$window_name" != "No Ses" ]]; then
      tmux rename-window "No Ses"
    fi
  else
    tmux rename-window "$session_name"
  fi

  # cd "$session_dir" >/dev/null || exit 1
  tmux respawn-pane -k -t "$pane_id" -c "$session_dir" "$last_default_command"
  tmux set-hook -t "$session" -a after-set-option "run-shell '\"$CURRENT_DIR/session.sh\" -a reload -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"
  # unset_tmux_hook "pane-focus-in" "$CURRENT_DIR/session.sh" "$pane_id"
}

main() {
  local action
  local pane_id
  local session_name
  local session_dir

  pane_id="$(tmux display-message -p "#{pane_id}")"

  local OPTIND o
  while getopts "a:c:m:p:n:d:" o; do
    case "${o}" in
      a)
        action="${OPTARG}"
        ;;
      c)
        _PENMUX_SCRIPTS="${OPTARG}"
        ;;
      m)
        _MODULE_PATH="${OPTARG}"
        ;;
      p)
        pane_id="${OPTARG}"
        ;;
      n)
        session_name="${OPTARG}"
        ;;
      d)
        session_dir="${OPTARG}"
        ;;
      *)
        echo >&2 "Invalid parameter"
        exit 1
        ;;
    esac
  done

  source "${_PENMUX_SCRIPTS}/variables.sh"
  source "${_PENMUX_SCRIPTS}/helpers.sh"

  # if supported_tmux_version_ok; then
  case "${action}" in
    "new")
      _new "$pane_id"
      ;;
    "stop")
      _stop "$pane_id"
      ;;
    "reload")
      _reload "$pane_id"
      ;;
    "init")
      _init "$pane_id" "$session_name" "$session_dir"
      ;;
    *)
      echo >&2 "Invalid action '${action}'"
      exit 1
      ;;
  esac
  # fi
}
main "$@"
