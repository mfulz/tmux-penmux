#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PENMUX_SCRIPTS=""
_MODULE_PATH=""

source "$CURRENT_DIR/shared.sh"

_new() {
  local pane_id="$1"
  local session_name="$(tmux command-prompt -p "Session Name: " "display-message -p '%%'")"
  local session_dir="$(_get_new_session_dir "$pane_id" "$session_name")"
  local no_confirm="$(penmux_module_get_option "$_MODULE_PATH" "NoConfirm")"
  local session_opts

  [[ -z "$session_name" ]] && exit 0

  if [ ! -d "$session_dir" ]; then
    err="$(mkdir -p "$session_dir" >/dev/null)" || {
    echo "Unable to create session dir: '$session_dir' ('$err')"
      exit 1
    }
  fi 

  if [ ! -e "$session_dir/.pmses" ]; then
    err="$(touch "$session_dir/.pmses" >/dev/null)" || {
    echo "Unable to create session file: '$session_dir/.pmses' ('$err')"
      exit 1
    }
  else
    if [[ "$no_confirm" != "true" ]]; then
      local user_select="$(tmux command-prompt -p "Session '$session_name' already exists. Overwrite? (y/n)" -1 "display-message -p '%%'")"
      [[ "$user_select" == "y" ]] || exit 0
    fi
  fi

  declare -A session_opts="($(penmux_module_get_exported_options "$pane_id"))"
  session_opts["SessionName"]="$session_name"
  session_opts["SessionDir"]="$session_dir"

  _array_to_session_file "$session_dir/.pmses" session_opts

  penmux_module_set_provider "$_MODULE_PATH" "SessionName" "$session_name" "$pane_id"
  penmux_module_set_provider "$_MODULE_PATH" "SessionDir" "$session_dir" "$pane_id"

  tmux respawn-pane -k -t "$pane_id" -c "$session_dir"

  penmux_module_notify_consumers "$_MODULE_PATH" "SessionDir" "$pane_id"
  penmux_module_notify_consumers "$_MODULE_PATH" "SessionName" "$pane_id"
}

_stop() {
  local pane_id="$1"
  local session_name="$(penmux_module_get_provider "$_MODULE_PATH" "SessionName" "$pane_id")"
  local session_dir="$(penmux_module_get_provider "$_MODULE_PATH" "SessionDir" "$pane_id")"
 
  if [ -n "$session_name" ] && [ -n "$session_dir" ]; then
    penmux_module_set_provider "$_MODULE_PATH" "SessionName" "" "$pane_id"
    penmux_module_set_provider "$_MODULE_PATH" "SessionDir" "" "$pane_id"

    tmux respawn-pane -k -t "$pane_id" -c "" "$SHELL"

    penmux_module_notify_consumers "$_MODULE_PATH" "SessionDir" "$pane_id"
    penmux_module_notify_consumers "$_MODULE_PATH" "SessionName" "$pane_id"
  fi
}

_load() {
  local pane_id="$1"
  local session_file="$2"
  local session_dir_act="$(penmux_module_get_provider "$_MODULE_PATH" "SessionDir" "$pane_id")"
  local auto_load="$(penmux_module_get_option "$_MODULE_PATH" "AutoLoad")"
  local session_opts

  [[ "$auto_load" != "true" && -n "$session_file" ]] && exit 0

  if [ -z "$session_file" ]; then
    session_file="$(tmux display-message -p '#{pane_current_path}')"
    session_file="$session_file/.pmses"
    session_file="$(realpath "$session_file")"
    [[ -e "$session_file" ]] || exit 1
  fi

  declare -A session_opts="($(_session_file_to_array "$session_file"))"
  [[ -v "session_opts[SessionDir]" ]] || exit 1
  [[ -v "session_opts[SessionName]" ]] || exit 1

  [[ "$session_dir_act" == "${session_opts[SessionDir]}" ]] && exit 0

  _unset_session "$pane_id"

  for key in "${!session_opts[@]}"; do
    [[ "$key" == "SessionDir" || "$key" == "SessionName" ]] && continue
    tmux set-option -p -t "$pane_id" "$key" "${session_opts[${key}]}"
  done

  penmux_module_set_provider "$_MODULE_PATH" "SessionName" "${session_opts[SessionName]}" "$pane_id"
  penmux_module_set_provider "$_MODULE_PATH" "SessionDir" "${session_opts[SessionDir]}" "$pane_id"

  tmux set-option -t "$pane_id" -p remain-on-exit on
  tmux send-keys -t "$pane_id" " exit" Enter
  tmux respawn-pane -k -t "$pane_id" -c "${session_opts[SessionDir]}" "$SHELL"
  tmux set-option -t "$pane_id" -p -u remain-on-exit

  penmux_module_notify_consumers "$_MODULE_PATH" "SessionDir" "$pane_id"
  penmux_module_notify_consumers "$_MODULE_PATH" "SessionName" "$pane_id"

}

_save() {
  local pane_id="$1"
  local session_name="$(penmux_module_get_provider "$_MODULE_PATH" "SessionName" "$pane_id")"
  local session_dir="$(penmux_module_get_provider "$_MODULE_PATH" "SessionDir" "$pane_id")"
  local session_file="$(realpath $session_dir/.pmses)"
  local session_opts

  declare -A session_opts="($(penmux_module_get_exported_options "$calling_pane_id"))"
  session_opts["SessionName"]="$session_name"
  session_opts["SessionDir"]="$session_dir"

  _array_to_session_file "$session_file" session_opts
}

main() {
  local action
  local pane_id
  local session_name
  local session_dir
  local session_file

  pane_id="$(tmux display-message -p "#D")"

  local OPTIND o
  while getopts "a:c:m:p:n:d:f:" o; do
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
      f)
        session_file="${OPTARG}"
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
    "load")
      _load "$pane_id" "$session_file"
      ;;
    "save")
      _save "$pane_id"
      ;;
    *)
      echo >&2 "Invalid action '${action}'"
      exit 1
      ;;
  esac
  # fi
}
main "$@"
