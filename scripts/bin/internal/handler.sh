#!/usr/bin/env bash

[[ "$#" -lt 1 ]] && { echo >&2 "Missing module file"; exit 1; }
_MODULE_FILE="$1"; shift
_MODULE_HANDLER_INC_FILE="$(dirname "$_MODULE_FILE")/$(basename "$_MODULE_FILE" .xml)/penmux_module_inc.sh"

[[ -e "$_MODULE_HANDLER_INC_FILE" ]] || { echo >&2 "Module has no handler inc file: '$_MODULE_HANDLER_INC_FILE'"; exit 1; }

_HANDLER_CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PENMUX_SCRIPTS="$_HANDLER_CURRENT_DIR/../../penmux"

source "$_PENMUX_SCRIPTS/inc.sh"
source "$_MODULE_HANDLER_INC_FILE"

main() {
  local action
  local pane_id
  local calling_pane_id
  local provider_name
  local provider_value
  local opt_volatile
  local func_name
  local hook
  local hook_option

	local OPTIND o
	while getopts "a:c:p:n:v:s:f:h:o:" o; do
		case "${o}" in
		a)
			action="${OPTARG}"
			;;
		c)
      # do not change !!! 
      calling_pane_id="${OPTARG}"
			;;
		p)
      # do not change !!! 
      pane_id="${OPTARG}"
			;;
		n)
      # do not change !!! 
      provider_name="${OPTARG}"
			;;
		v)
      # do not change !!! 
      provider_value="${OPTARG}"
			;;
		s)
      opt_volatile="${OPTARG}"
			;;
		f)
      func_name="${OPTARG}"
			;;
		h)
      hook="${OPTARG}"
			;;
		o)
      hook_option="${OPTARG}"
			;;
    *)
      # do not change !!! 
      echo >&2 "Invalid parameter"
      exit 1
      ;;
  esac
done

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
    # Will be called when options are set
    # If not needed just exit 0
    _optionsnotify "$pane_id" "$provider_name" "$provider_value" "$opt_volatile"
    exit 0
    ;;
  "consumes")
    # Will be called when options are set
    # If not needed just exit 0
    _consumes "$pane_id" "$provider_name" "$provider_value"
    exit 0
    ;;
  "keyfunc")
    # Will be called from keytable definition
    _keyfunc "$calling_pane_id" "$pane_id" "$func_name"
    exit 0
    ;;
  "hook")
    # running registered hooks
    _hook "$pane_id" "$hook" "$hook_option"
    exit 0
    ;;
  *)
    echo >&2 "Invalid action '${action}'"
    exit 1
    ;;
esac
}
main "$@"
