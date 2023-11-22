#!/usr/bin/env bash

### Module handle script ###
# Has to be implemented by every module

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PENMUX_SCRIPTS=""
_MODULE_PATH=""

# source "$CURRENT_DIR/shared.sh"

_load() {
  return
}

_unload() {
  return
}

_run() {
  local pane_id="$1"
  local no_confirm="$(penmux_module_get_option "$_MODULE_PATH" "NoConfirm" "$pane_id")"
  local csv
  local cmd

  csv="$("$CURRENT_DIR/commander.sh" -a select_csv -c "$_PENMUX_SCRIPTS" -m "$_MODULE_PATH" -p "$pane_id")"
  [[ -z "$csv" ]] && return

  if [[ "$csv" == *.sh ]]; then
    local command_search_path="$(penmux_module_get_option "$_MODULE_PATH" "CommandSearchPath" "$pane_id")"
    local cmd_file="$(penmux_expand_tmux_format_path "$pane_id" "$command_search_path/$csv")"

    "$cmd_file" -a run -c "$_PENMUX_SCRIPTS" -m "$_MODULE_PATH" -p "$pane_id"
    return
  fi

  cmd="$("$CURRENT_DIR/commander.sh" -a select_cmd -c "$_PENMUX_SCRIPTS" -m "$_MODULE_PATH" -p "$pane_id" -f "$csv")"

  if [[ "$no_confirm" == "true" ]]; then
    tmux send-keys "$cmd" Enter
  else
    tmux send-keys "$cmd"
  fi
}

_cmd() {
  return
}

_optionsnotify() {
  return
}

_consumes() {
  return
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

source "${_PENMUX_SCRIPTS}/inc.sh"

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
    _run "$pane_id"
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
    _optionsnotify "$pane_id" "$provider_name" "$provider_value"
    exit 0
    ;;
  "consumes")
    # Will be called as default command for
    # new panes
    # If not needed just exit 0
    _consumes "$pane_id" "$provider_name" "$provider_value"
    exit 0
    ;;
  *)
    echo >&2 "Invalid action '${action}'"
    exit 1
    ;;
esac
}
main "$@"
