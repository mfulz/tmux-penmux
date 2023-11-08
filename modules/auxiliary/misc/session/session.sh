#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PENMUX_SCRIPTS=""
_MODULE_PATH=""

source "$CURRENT_DIR/shared.sh"

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

  penmux_module_set_provider "$_MODULE_PATH" "SessionName" "$session_name" "$pane_id" "pane"
  penmux_module_set_provider "$_MODULE_PATH" "SessionDir" "$session_dir" "$pane_id" "pane"

  tmux respawn-pane -k -t "$pane_id" -c "$session_dir"

  penmux_module_notify_consumers "$_MODULE_PATH" "SessionDir" "$pane_id"
  penmux_module_notify_consumers "$_MODULE_PATH" "SessionName" "$pane_id"
}

_stop() {
  local pane_id="$1"
  local session_name="$(penmux_module_get_provider "$_MODULE_PATH" "SessionName" "$pane_id")"
  local session_dir="$(penmux_module_get_provider "$_MODULE_PATH" "SessionDir" "$pane_id")"
 
  if [ -n "$session_name" ] && [ -n "$session_dir" ]; then
    penmux_module_set_provider "$_MODULE_PATH" "SessionName" "" "$pane_id" "pane" "1"
    penmux_module_set_provider "$_MODULE_PATH" "SessionDir" "" "$pane_id" "pane" "1"

    tmux respawn-pane -k -t "$pane_id" -c "" "$SHELL"

    penmux_module_notify_consumers "$_MODULE_PATH" "SessionDir" "$pane_id"
    penmux_module_notify_consumers "$_MODULE_PATH" "SessionName" "$pane_id"
  fi
}

  main() {
  local action
  local pane_id
  local session_name
  local session_dir

  pane_id="$(tmux display-message -p "#D")"

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
    *)
      echo >&2 "Invalid action '${action}'"
      exit 1
      ;;
  esac
  # fi
}
main "$@"
