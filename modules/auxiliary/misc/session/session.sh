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
    err="$(mkdir -p "$session_dir" 2>&1 1>/dev/null)" || {
      echo >&2 "Unable to create session dir: '$session_dir' ('$err')"
      return 1
    }
  fi 

  if [ ! -e "$session_dir/.pmses" ]; then
    err="$(touch "$session_dir/.pmses" 2>&1 1>/dev/null)" || {
      echo >&2 "Unable to create session file: '$session_dir/.pmses' ('$err')"
      return 1
    }
  else
    if [[ "$no_confirm" != "true" ]]; then
      local user_select="$(tmux command-prompt -p "Session '$session_name' already exists. Overwrite? (y/n)" -1 "display-message -p '%%'")"
      [[ "$user_select" == "y" ]] || exit 0
    fi
  fi

  penmux_module_set_option "$_MODULE_PATH" "SessionName" "$session_name" "$pane_id"
  penmux_module_set_option "$_MODULE_PATH" "SessionDir" "$session_dir/" "$pane_id"

  declare -A session_opts="($(penmux_module_get_exported_options "$pane_id"))"
  _array_to_session_file "$session_dir/.pmses" session_opts

  tmux respawn-pane -k -t "$pane_id" -c "$session_dir"

  penmux_module_notify_consumers "$_MODULE_PATH" "SessionName" "$pane_id"
  penmux_module_notify_consumers "$_MODULE_PATH" "SessionDir" "$pane_id"
}

_stop() {
  local pane_id="$1"
  local session_name="$(penmux_module_get_option "$_MODULE_PATH" "SessionName" "$pane_id")"
  local session_dir="$(penmux_module_get_option "$_MODULE_PATH" "SessionDir" "$pane_id")"

  penmux_module_set_option "$_MODULE_PATH" "SessionName" "" "$pane_id"
  penmux_module_set_option "$_MODULE_PATH" "SessionDir" "" "$pane_id"
  penmux_module_set_option "$_MODULE_PATH" "AutoLoad" ""
  penmux_module_set_option "$_MODULE_PATH" "AutoSave" ""
  penmux_module_set_option "$_MODULE_PATH" "NoConfirm" ""
  penmux_module_set_option "$_MODULE_PATH" "UseCwd" ""
  penmux_module_set_option "$_MODULE_PATH" "SessionDirBase" ""
 
  if [ -n "$session_name" ] && [ -n "$session_dir" ]; then
    tmux respawn-pane -k -t "$pane_id" -c "" "$SHELL"

    penmux_module_notify_consumers "$_MODULE_PATH" "SessionName" "$pane_id"
    penmux_module_notify_consumers "$_MODULE_PATH" "SessionDir" "$pane_id"
  fi
}

_load() {
  local pane_id="$1"
  local session_file="$2"
  local session_dir_act="$(penmux_module_get_option "$_MODULE_PATH" "SessionDir" "$pane_id")"
  local auto_load="$(penmux_module_get_option "$_MODULE_PATH" "AutoLoad" "$pane_id")"
  local session_opts
  local loaded="$(penmux_module_is_loaded "auxilliary/misc/session.xml")"

  [[ -z "$loaded" ]] && exit 0

  # tmux display-message -d 10000 "$auto_load"

  [[ "$auto_load" != "true" && -n "$session_file" ]] && exit 0

  if [ -z "$session_file" ]; then
    session_file="$(tmux display-message -p '#{pane_current_path}')"
    session_file="$session_file/.pmses"
    session_file="$(realpath "$session_file")"
    [[ -e "$session_file" ]] || {
      echo >&2 "Session file '$session_file' does not exist"
      return 1
    }
  fi

  declare -A session_opts="($(_session_file_to_array "$session_file"))"
  [[ -v "session_opts[@penmux-SessionDir]" ]] || {
    echo >&2 "Session file '$session_file' corrupt. Missing 'SessionDir'"
    return 1
  }
  [[ -v "session_opts[@penmux-SessionName]" ]] || {
    echo >&2 "Session file '$session_file' corrupt. Missing 'SessionName'"
    return 1
  }

  [[ "$session_dir_act" == "${session_opts["@penmux-SessionDir"]}" ]] && exit 0

  _unset_session "$pane_id"

  for key in "${!session_opts[@]}"; do
    tmux set-option -p -t "$pane_id" "$key" "${session_opts[${key}]}"
  done

  tmux set-option -t "$pane_id" -p remain-on-exit on
  tmux send-keys -t "$pane_id" " exit" Enter
  tmux respawn-pane -k -t "$pane_id" -c "${session_opts["@penmux-SessionDir"]}" "$SHELL -c ' cd . && $SHELL'"
  # tmux respawn-pane -k -t "$pane_id" -c "${session_opts["@penmux-SessionDir"]}" "$SHELL"
  # dirty hack (dunno what's wrong here)
  # TODO:Fix
  # tmux send-keys " cd . && reset" Enter
  tmux set-option -t "$pane_id" -p -u remain-on-exit

  penmux_module_notify_consumers "$_MODULE_PATH" "SessionName" "$pane_id"
  penmux_module_notify_consumers "$_MODULE_PATH" "SessionDir" "$pane_id"
}

_save() {
  local pane_id="$1"
  local session_name="$(penmux_module_get_option "$_MODULE_PATH" "SessionName")"
  local session_dir="$(penmux_module_get_option "$_MODULE_PATH" "SessionDir")"
  local session_file="$(realpath $session_dir/.pmses)"
  local session_opts

  if [ -z "$session_name" ] || [ -z "$session_dir" ]; then
    echo >&2 "No session started"
    return 1
  fi

  declare -A session_opts="($(penmux_module_get_exported_options "$pane_id"))"

  _array_to_session_file "$session_file" session_opts
}

main() {
  local action
  local pane_id
  local session_name
  local session_dir
  local session_file
  local err

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

  source "${_PENMUX_SCRIPTS}/exported.sh"

  # if supported_tmux_version_ok; then
  case "${action}" in
    "new")
      err="$(_new "$pane_id" 2>&1 1>/dev/null)" || {
        tmux display-message -d 5000 "Error: '$err'"
        exit 0
      }
      ;;
    "stop")
      err="$(_stop "$pane_id" 2>&1 1>/dev/null)" || {
        tmux display-message -d 5000 "Error: '$err'"
        exit 0
      }
      ;;
    "load")
      err="$(_load "$pane_id" "$session_file" 2>&1 1>/dev/null)" || {
        tmux display-message -d 5000 "Error: '$err'"
        exit 0
      }
      ;;
    "save")
      err="$(_save "$pane_id" 2>&1 1>/dev/null)" || {
        tmux display-message -d 5000 "Error: '$err'"
        exit 0
      }
      ;;
    *)
      tmux display-message -d 5000 "Error: 'Invalid action ${action}'"
      exit 0
      ;;
  esac
  # fi
}
main "$@"
