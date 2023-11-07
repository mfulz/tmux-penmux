#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PENMUX_SCRIPTS=""
_MODULE_PATH=""

source "$CURRENT_DIR/shared.sh"

_set_logging_variable() {
  local pane_id="$1"
  tmux set-option -t "${pane_id}" -pq "@penmux-scriptlog-logfile" "$(_get_log_file "$pane_id")"
}

_unset_logging_variable() {
  local pane_id="$1"
	tmux set-option -t "${pane_id}" -upq "@penmux-scriptlog-logfile"
}

_unset_stored_pane_title() {
  local pane_id="$1"
	tmux set-option -t "${pane_id}" -upq "@penmux-scriptlog-title"
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
	tmux set-option -t "${pane_id}" -pq "@penmux-scriptlog-title" "${pane_title}"
}

_get_stored_pane_title() {
  local pane_id="$1"
	local pane_title="$(tmux show-option -t "${pane_id}" -pqv "@penmux-scriptlog-title")"

  echo "$pane_title"
}

_set_pane_title() {
  local pane_id="$1"
	local pane_title="$(_get_pane_title "$pane_id")"
  tmux select-pane -t "${pane_id}" -T "${pane_title} (logging)"
}

_restore_pane_title() {
  local pane_id="$1"
	local pane_title="$(tmux show-option -t "${pane_id}" -pqv "@penmux-scriptlog-title")"
	tmux select-pane -t "${pane_id}" -T "${pane_title}"
	tmux set-option -t "${pane_id}" -upq "@penmux-scriptlog-title"
}

# stop logging
_stop() {
  local pane_id="$1"
	_is_logging "$pane_id" && {
    _unset_logging_variable "$pane_id"
    tmux send-keys -t "${pane_id}" " exit" Enter

    # _restore_pane_title

    # tmux kill-pane -t "$_PANE_ID"
  }
}

# revert logging
_revert() {
  local pane_id="$1"
	_is_logging "$pane_id" && {
    _unset_logging_variable "$pane_id"
    _restore_pane_title "$pane_id"
    _unset_stored_pane_title "$pane_id"
  }
  tmux set-hook -t "$pane_id" -up pane-title-changed
  tmux respawn-pane -k -t "$pane_id" "$SHELL"
}

# start logging
_start() {
  local pane_id="$1"
  local log_file="$(_get_act_log_file "$pane_id")"
  local new_file="$(_get_log_file "$pane_id")"
  local session_dir="$(get_tmux_option "@penmux-session-dir" "" "$pane_id")"
  local logdir

  if [[ "$log_file" != "$new_file" ]]; then
    logdir="$(_get_log_dir "$pane_id")"
    if [ ! -d "$logdir" ]; then
      err="$(mkdir -p "$logdir" >/dev/null)" || {
        echo "Unable to create logdir: '$logdir' ('$err')"
        exit 1
      }
    fi

    _store_pane_title "$pane_id"
    _set_pane_title "$pane_id"
    _set_logging_variable "$pane_id"

    tmux set-hook -t "$pane_id" -p pane-title-changed "run-shell '\"$CURRENT_DIR/scriptlog.sh\" -a title -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\" -p \"$pane_id\"'"
    tmux set-hook -t "$pane_id" -up pane-died
    tmux set-option -t "$pane_id" -up remain-on-exit
    if [ -n "$session_dir" ]; then
      cd "$session_dir"; script -q -T "${new_file}.time" "$new_file"
    else
      script -q -T "${new_file}.time" "$new_file"
    fi
  fi
}

# restart logging
_restart() {
  local pane_id="$1"
  local log_file="$(_get_act_log_file "$pane_id")"
  local new_file="$(_get_log_file "$pane_id")"
  local session_dir="$(get_tmux_option "@penmux-session-dir" "" "$pane_id")"

  _is_logging "$pane_id" || exit 0
  unset_tmux_hook "after-set-option" "$CURRENT_DIR/scriptlog.sh" "$session"

  if [[ "$log_file" != "$new_file" ]]; then
    tmux set-hook -t "$pane_id" -up pane-title-changed
    if [ -n "$session_dir" ]; then
      tmux set-hook -t "$pane_id" -p pane-died "respawn-pane -c \"$session_dir\" -t \"$pane_id\""
    else
      tmux set-hook -t "$pane_id" -p pane-died "respawn-pane -t \"$pane_id\""
    fi
    tmux set-option -t "$pane_id" -p remain-on-exit on
    _stop "$pane_id"
  fi

  tmux set-hook -t "$session" -a after-set-option "run-shell '\"$CURRENT_DIR/scriptlog.sh\" -a restart_all -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"
}

# restart logging for all panes
_restart_all() {
  local panes
  local session="$(tmux display-message -p "#S")"

  # tmux set-hook -t "$session" -u after-set-option
  unset_tmux_hook "after-set-option" "$CURRENT_DIR/scriptlog.sh" "$session"
  panes="$(_get_all_panes)"
  while IFS= read -r p; do
    tmux run-shell "\"$CURRENT_DIR/scriptlog.sh\" -a restart -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\" -p \"$p\""
  done <<< "$panes"
  tmux set-hook -t "$session" -a after-set-option "run-shell '\"$CURRENT_DIR/scriptlog.sh\" -a restart_all -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"
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

  source "${_PENMUX_SCRIPTS}/variables.sh"
  source "${_PENMUX_SCRIPTS}/helpers.sh"

  # if supported_tmux_version_ok; then
  case "${action}" in
    "start")
      _start "$pane_id"
      ;;
    "stop")
      _stop "$pane_id"
      ;;
    "restart")
      _restart "$pane_id"
      ;;
    "restart_all")
      _restart_all
      ;;
    "title")
      _title "$pane_id"
      ;;
    "revert")
      _revert "$pane_id"
      ;;
    *)
      echo >&2 "Invalid action '${action}'"
      exit 1
      ;;
  esac
  # fi
}
main "$@"
