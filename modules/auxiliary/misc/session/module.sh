#!/usr/bin/env bash

### Module handle script ###
# Has to be implemented by every module

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PENMUX_SCRIPTS=""
_MODULE_PATH=""

source "$CURRENT_DIR/shared.sh"

_load() {
  local session="$(tmux display-message -p "#S")"

  tmux bind -T penmux_keytable "s" switch-client -T penmux_module_session_keytable
  tmux bind -T penmux_module_session_keytable "n" "run-shell '\"$CURRENT_DIR/session.sh\" -a new -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"
  tmux bind -T penmux_module_session_keytable "s" "run-shell '\"$CURRENT_DIR/session.sh\" -a stop -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"
  
  tmux set-hook -t "$session" -a after-set-option "run-shell '\"$CURRENT_DIR/session.sh\" -a reload -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"
  tmux set-hook -t "$session" -a after-select-pane "run-shell '\"$CURRENT_DIR/session.sh\" -a reload -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"
  tmux set-hook -t "$session" -a after-split-window "run-shell '\"$CURRENT_DIR/session.sh\" -a reload -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"
  tmux set-hook -t "$session" -a after-select-window "run-shell '\"$CURRENT_DIR/session.sh\" -a reload -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"
  tmux set-hook -t "$session" -a after-new-window "run-shell '\"$CURRENT_DIR/session.sh\" -a reload -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"

  tmux display-message -d 5000 "session loaded and running"
}

_unload() {
  local session="$(tmux display-message -p "#S")"
  local panes="$(tmux list-panes -F "#D")"

  tmux unbind -T penmux_module_session_keytable "s"
  tmux unbind -T penmux_module_session_keytable "n"
  tmux unbind -T penmux_keytable "s"

  while IFS= read -r p; do
    tmux run-shell "\"$CURRENT_DIR/session.sh\" -a stop -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\" -p \"$p\""
  done <<< "$panes"

  unset_tmux_hook "after-set-option" "$CURRENT_DIR/session.sh" "$session"
  unset_tmux_hook "after-select-pane" "$CURRENT_DIR/session.sh" "$session"
  unset_tmux_hook "after-split-window" "$CURRENT_DIR/session.sh" "$session"
  unset_tmux_hook "after-select-window" "$CURRENT_DIR/session.sh" "$session"
  unset_tmux_hook "after-new-window" "$CURRENT_DIR/session.sh" "$session"

  tmux display-message -d 5000 "session stopped and unloaded"
}

main() {
  local action

	local OPTIND o
	while getopts "a:vc:m:" o; do
		case "${o}" in
		a)
			action="${OPTARG}"
			;;
		v)
      # do not change !!! 
      echo "1"
      exit 0
      ;;
    c)
      # do not change !!! 
      _PENMUX_SCRIPTS="${OPTARG}"
      ;;
		m)
      _MODULE_PATH="${OPTARG}"
			;;
    *)
      # do not change !!! 
      echo >&2 "Invalid parameter"
      exit 1
      ;;
  esac
done

source "${_PENMUX_SCRIPTS}/variables.sh"
source "${_PENMUX_SCRIPTS}/helpers.sh"

case "${action}" in
  "load")
    # Will be called on module load
    # Used for initialization stuff
    # If not needed just exit 0
    _load
    exit 0
    ;;
  "unload")
    # Will be called on module unload
    # Used for cleanup stuff
    # If not needed just exit 0
    _unload
    exit 0
    ;;
  "run")
    # Will be called on module run
    # Used for execution stuff
    # If not needed just exit 0
    # ## this should only be the case for passive modules, that run in background
    # ## doing their work over tmux hooks or similar
    exit 0
    ;;
  *)
    echo >&2 "Invalid action '${action}'"
    exit 1
    ;;
esac
}
main "$@"
