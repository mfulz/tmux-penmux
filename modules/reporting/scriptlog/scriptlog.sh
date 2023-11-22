#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PENMUX_SCRIPTS=""
_MODULE_PATH=""

source "$CURRENT_DIR/shared.sh"

_set_logging_variable() {
  local pane_id="$1"
  local log_file="$(_get_log_file "$pane_id")"
  penmux_module_set_option "$_MODULE_PATH" "LogFile" "$log_file" "$pane_id"
}

_unset_logging_variable() {
  local pane_id="$1"
  penmux_module_set_option "$_MODULE_PATH" "LogFile" "" "$pane_id"
}

_unset_stored_pane_title() {
  local pane_id="$1"
  penmux_module_set_option "$_MODULE_PATH" "Title" "" "$pane_id"
}

_get_pane_title() {
  local pane_id="$1"
	local pane_title="$(tmux display-message -t "${pane_id}" -p "#{pane_title}")"
  pane_title="${pane_title/" (logging)"/}"

  echo "$pane_title"
}

_store_pane_title() {
  local pane_id="$1"
	local pane_title="$(_get_pane_title "$pane_id")"
  penmux_module_set_option "$_MODULE_PATH" "Title" "$pane_title" "$pane_id"
}

_get_stored_pane_title() {
  local pane_id="$1"
  local pane_title="$(penmux_module_get_option "$_MODULE_PATH" "Title" "$pane_id")"

  echo "$pane_title"
}

_set_pane_title() {
  local pane_id="$1"
	local pane_title="$(_get_pane_title "$pane_id")"
  tmux select-pane -t "${pane_id}" -T "${pane_title} (logging)"
}

_restore_pane_title() {
  local pane_id="$1"
  local pane_title="$(penmux_module_get_option "$_MODULE_PATH" "Title" "$pane_id")"
	tmux select-pane -t "${pane_id}" -T "${pane_title}"
  penmux_module_set_option "$_MODULE_PATH" "Title" "" "$pane_id"
}

# revert logging
_revert() {
  local pane_id="$1"
	_is_logging "$pane_id" && {
    _unset_logging_variable "$pane_id"
    _restore_pane_title "$pane_id"
    _unset_stored_pane_title "$pane_id"
  }
  # tmux set-hook -t "$pane_id" -up pane-title-changed
  tmux respawn-pane -k -t "$pane_id" "$SHELL -c ' cd . && $SHELL'"
}

# start logging
_start() {
  local pane_id="$1"
  local log_file="$(_get_act_log_file "$pane_id")"
  local new_file="$(_get_log_file "$pane_id")"
  local logdir

  echo "$pane_id a: $log_file n: $new_file" >> /tmp/fuckoff

  if [[ "$log_file" != "$new_file" ]]; then
    logdir="$(_get_log_dir "$pane_id")"
    if [ ! -d "$logdir" ]; then
      err="$(mkdir -p "$logdir" 2>&1 1>/dev/null)" || {
        echo >&2 "Unable to create logdir: '$logdir' ('$err')"
        return 1
      }
    fi

    _store_pane_title "$pane_id"
    _set_pane_title "$pane_id"
    _set_logging_variable "$pane_id"

    # tmux set-hook -t "$pane_id" -p pane-title-changed "run-shell '\"$CURRENT_DIR/scriptlog.sh\" -a title -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\" -p \"$pane_id\"'"
    tmux respawn-pane -k -t "$pane_id" "$SHELL -c ' cd . && script -q -T \"${new_file}.time\" \"$new_file\"'"
  fi
}

# restart logging
_restart() {
  local pane_id="$1"
  local log_file="$(_get_act_log_file "$pane_id")"
  local new_file="$(_get_log_file "$pane_id")"

  # _is_logging "$pane_id" || exit 0

  echo "$pane_id a: $log_file n: $new_file" >> /tmp/fuckoff

  if [[ "$log_file" != "$new_file" ]]; then
    _revert "$pane_id"
    # tmux run-shell "\"$CURRENT_DIR/scriptlog.sh\" -a revert -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\" -p \"$pane_id\""

    # tmux respawn-pane -k -t "$pane_id" "\"$CURRENT_DIR/scriptlog.sh\" -a start -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\" -p \"$pane_id\""
    tmux run-shell -t "$pane_id" "\"$CURRENT_DIR/scriptlog.sh\" -a start -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\" -p \"$pane_id\""
    # tmux set-hook -t "$pane_id" -up pane-title-changed
  fi
}

# title changed
# check if logpath is different if not just add (logging) status to 
# pane title and store orig title
_title() {
  local pane_id="$1"
  local log_file="$(_get_act_log_file "$pane_id")"
  local new_file="$(_get_log_file "$pane_id")"

  _is_logging "$pane_id" || exit 0

  if [[ "$log_file" != "$new_file" ]]; then
    tmux set-hook -t "$pane_id" -up pane-title-changed
    tmux set-hook -t "$pane_id" -p pane-died "respawn-pane -t \"$pane_id\""
    tmux set-option -t "$pane_id" -p remain-on-exit on
    _stop
  elif [[ "$(_get_pane_title "$pane_id")" != "$(_get_stored_pane_title "$pane_id")" ]]; then
    tmux set-hook -t "$pane_id" -up pane-title-changed
    _store_pane_title "$pane_id"
    _set_pane_title "$pane_id"
    tmux set-hook -t "$pane_id" -p pane-title-changed "run-shell '\"$CURRENT_DIR/scriptlog.sh\" -a title -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\" -p \"$pane_id\"'"
  fi
}

main() {
	local action
  local pane_id

	pane_id="$(tmux display-message -p "#{pane_id}")"

	local OPTIND o
	while getopts "a:c:m:p:" o; do
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
		*)
			echo >&2 "Invalid parameter"
			exit 1
			;;
		esac
	done

  source "${_PENMUX_SCRIPTS}/exported.sh"

  # if supported_tmux_version_ok; then
  case "${action}" in
    "start")
      err="$(_start "$pane_id")" || {
        tmux display-message -d 5000 "Error: '$err'"
        exit 0
      }
      ;;
    "restart")
      err="$(_restart "$pane_id")" || {
        tmux display-message -d 5000 "Error: '$err'"
        exit 0
      }
      ;;
    "title")
      err="$(_title "$pane_id")" || {
        tmux display-message -d 5000 "Error: '$err'"
        exit 0
      }
      ;;
    "revert")
      err="$(_revert "$pane_id")" || {
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
