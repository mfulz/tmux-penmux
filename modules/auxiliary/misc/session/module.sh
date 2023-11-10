#!/usr/bin/env bash

### Module handle script ###
# Has to be implemented by every module

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PENMUX_SCRIPTS=""
_MODULE_PATH=""

source "$CURRENT_DIR/shared.sh"

_load() {
  local session="$(tmux display-message -p "#{session_id}")"

  tmux bind -T penmux_keytable "s" switch-client -T penmux_module_session_keytable
  tmux bind -T penmux_module_session_keytable "n" "run-shell '\"$CURRENT_DIR/session.sh\" -a new -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"
  tmux bind -T penmux_module_session_keytable "e" "run-shell '\"$CURRENT_DIR/session.sh\" -a stop -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"
  tmux bind -T penmux_module_session_keytable "l" "run-shell '\"$CURRENT_DIR/session.sh\" -a load -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\"'"
  
  tmux set-option -t "$session" automatic-rename-format '#{?#{==:#{@penmux-providers-SessionName},},No Session,#{@penmux-providers-SessionName}} (#{?#{==:#{@penmux-providers-SessionDir},},CWD: #{pane_current_path},CSD: #{@penmux-providers-SessionDir}})'
  tmux set-option -t "$session" status-interval 10
  tmux set-option -t "$session" automatic-rename on

  tmux display-message -d 5000 "session loaded and running"
}

_unload() {
  local session="$(tmux display-message -p "#S")"
  local panes="$(tmux list-panes -F "#D")"

  tmux unbind -T penmux_module_session_keytable "l"
  tmux unbind -T penmux_module_session_keytable "e"
  tmux unbind -T penmux_module_session_keytable "n"
  tmux unbind -T penmux_keytable "s"

  while IFS= read -r p; do
    tmux run-shell "\"$CURRENT_DIR/session.sh\" -a stop -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\" -p \"$p\""
  done <<< "$panes"

  tmux set-option -t "$session" -u automatic-rename-format
  tmux set-option -t "$session" -u status-interval
  tmux set-option -t "$session" -u automatic-rename

  tmux display-message -d 5000 "session stopped and unloaded"
}

_cmd() {
  local calling_pane_id="$1"
  local pane_id="$2"
  local session_name="$(penmux_module_get_provider "$_MODULE_PATH" "SessionName" "$calling_pane_id")"
  local session_dir="$(penmux_module_get_provider "$_MODULE_PATH" "SessionDir" "$calling_pane_id")"
  local session_opts

  if [ -n "$session_name" ] && [ -n "$session_dir" ]; then
    penmux_module_set_provider "$_MODULE_PATH" "SessionName" "$session_name" "$pane_id"
    penmux_module_set_provider "$_MODULE_PATH" "SessionDir" "$session_dir" "$pane_id"

    declare -A session_opts="($(penmux_module_get_exported_options "$calling_pane_id"))"
    for key in "${!session_opts[@]}"; do
      tmux set-option -p -t "$pane_id" "$key" "${session_opts[${key}]}"
    done

    tmux respawn-pane -k -t "$pane_id" -c "$session_dir" "$SHELL"

    penmux_module_notify_consumers "$_MODULE_PATH" "SessionDir" "$pane_id"
    penmux_module_notify_consumers "$_MODULE_PATH" "SessionName" "$pane_id"
  else
    tmux respawn-pane -k -t "$pane_id" "$SHELL"
  fi
}

_optionsnotify() {
  local calling_pane_id="$1"
  local pane_id="$2"
  local session_name="$(penmux_module_get_provider "$_MODULE_PATH" "SessionName" "$calling_pane_id")"
  local session_dir="$(penmux_module_get_provider "$_MODULE_PATH" "SessionDir" "$calling_pane_id")"

  if [ -n "$session_name" ] && [ -n "$session_dir" ]; then
    penmux_module_set_provider "$_MODULE_PATH" "SessionName" "$session_name" "$pane_id"
    penmux_module_set_provider "$_MODULE_PATH" "SessionDir" "$session_dir" "$pane_id"

    tmux respawn-pane -k -t "$pane_id" -c "$session_dir" "$SHELL"

    penmux_module_notify_consumers "$_MODULE_PATH" "SessionDir" "$pane_id"
    penmux_module_notify_consumers "$_MODULE_PATH" "SessionName" "$pane_id"
  else
    tmux respawn-pane -k -t "$pane_id" "$SHELL"
  fi
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
  "cmd")
    # Will be called as default command for
    # new panes
    # If not needed just exit 0
    _cmd "$calling_pane_id" "$pane_id"
    exit 0
    ;;
  "optionsnotify")
    # Will be called as default command for
    # new panes
    # If not needed just exit 0
    _optionsnotify "$calling_pane_id" "$pane_id"
    exit 0
    ;;
  *)
    echo >&2 "Invalid action '${action}'"
    exit 1
    ;;
esac
}
main "$@"
