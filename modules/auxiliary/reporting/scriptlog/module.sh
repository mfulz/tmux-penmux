#!/usr/bin/env bash

### Module handle script ###
# Has to be implemented by every module

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PENMUX_SCRIPTS=""
_MODULE_PATH=""

source "$CURRENT_DIR/shared.sh"

_load() {
  local session="$(tmux display-message -p "#{session_id}")"
  local logexisting="$(penmux_module_get_option "$_MODULE_PATH" "LogExisting")"
  local logdir
  local panes

  which script >/dev/null 2>&1 || {
    echo "Cannot find 'script'. Either it is not installed or not in path. Please make sure you have installed util-linux"
    exit 1
  }

  if [[ "$logexisting" == "true" ]]; then
    panes="$(tmux list-panes -s -t "$session" -F "#D")"
    while IFS= read -r p; do
      tmux respawn-pane -k -t "$p" "\"$CURRENT_DIR/scriptlog.sh\" -a start -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\" -p \"$p\""
    done <<< "$panes"
  fi

  # tmux set-option -t "$session" default-command "\"$CURRENT_DIR/scriptlog.sh\" -a start -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\""
  # tmux set-hook -t "$session" -a session-renamed "run-shell '\"$CURRENT_DIR/scriptlog.sh\" -a restart -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"
  # tmux set-hook -t "$session" -a window-renamed "run-shell '\"$CURRENT_DIR/scriptlog.sh\" -a restart -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"
  # tmux set-hook -t "$session" -a after-set-option "run-shell '\"$CURRENT_DIR/scriptlog.sh\" -a restart_all -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"

  tmux display-message -d 5000 "scriptlog loaded and running"
}

_unload() {
  local session="$(tmux display-message -p "#{session_id}")"
  local panes="$(tmux list-panes -s -t "$session" -F "#D")"

  # tmux set-option -t "$session" -u default-command "\"$CURRENT_DIR/scriptlog.sh\" -a start -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\""
  # tmux set-hook -t "$session" -u session-renamed "run-shell '\"$CURRENT_DIR/scriptlog.sh\" -a restart -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"
  # tmux set-hook -t "$session" -u window-renamed "run-shell '\"$CURRENT_DIR/scriptlog.sh\" -a restart -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"
  # tmux set-hook -t "$session" -u after-set-option "run-shell '\"$CURRENT_DIR/scriptlog.sh\" -a restart_all -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"
  # unset_tmux_hook "session-renamed" "$CURRENT_DIR/scriptlog.sh" "$session"
  # unset_tmux_hook "window-renamed" "$CURRENT_DIR/scriptlog.sh" "$session"
  # unset_tmux_hook "after-set-option" "$CURRENT_DIR/scriptlog.sh" "$session"

  while IFS= read -r p; do
    tmux run-shell -t "$p" "\"$CURRENT_DIR/scriptlog.sh\" -a revert -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\" -p \"$p\""
  done <<< "$panes"

  tmux display-message -d 5000 "scriptlog stopped and unloaded"
}

_cmd() {
  local calling_pane_id="$1"
  local pane_id="$2"

  tmux respawn-pane -k -t "$pane_id" "\"$CURRENT_DIR/scriptlog.sh\" -a start -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\" -p \"$pane_id\""
}

_notify() {
  local pane_id="$1"
  local session="$(tmux display-message -p "#{session_id}")"
  local panes="$(tmux list-panes -s -t "$session" -F "#D")"

  while IFS= read -r p; do
    tmux run-shell -t "$p" "\"$CURRENT_DIR/scriptlog.sh\" -a restart -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\" -p \"$p\""
  done <<< "$panes"
}

main() {
  local action
  local pane_id
  local calling_pane_id
  local provider_name
  local provider_value

	local OPTIND o
	while getopts "a:vc:m:o:p:k:i:" o; do
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
		o)
      calling_pane_id="${OPTARG}"
			;;
		p)
      pane_id="${OPTARG}"
			;;
		k)
      provider_name="${OPTARG}"
			;;
		i)
      provider_value="${OPTARG}"
			;;
    *)
      # do not change !!! 
      echo >&2 "Invalid parameter"
      exit 1
      ;;
  esac
done

source "${_PENMUX_SCRIPTS}/exported.sh"

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
  "cmd")
    # Will be called as default command for
    # new panes
    # If not needed just exit 0
    _cmd "$calling_pane_id" "$pane_id"
    exit 0
    ;;
  "notify")
    # Will be called as default command for
    # new panes
    # If not needed just exit 0
    _notify "$pane_id"
    exit 0
    ;;
  *)
    echo >&2 "Invalid action '${action}'"
    exit 1
    ;;
esac
}
main "$@"
