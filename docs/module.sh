#!/usr/bin/env bash

### Module handle script ###
# Has to be implemented by every module

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PENMUX_SCRIPTS=""
_MODULE_PATH=""

# uncomment this if your module has a shared function script
# source "$CURRENT_DIR/shared.sh"

_load() {
  return
}

_unload() {
  return
}

_cmd() {
  # local calling_pane_id="$1"
  # local pane_id="$2"

  return
}

_optionsnotify() {
  # local pane_id="$1"
  # local opt="$2"
  # local val="$3"

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
      # do not change !!! 
      _MODULE_PATH="${OPTARG}"
			;;
		o)
      # do not change !!! 
      calling_pane_id="${OPTARG}"
			;;
		p)
      # do not change !!! 
      pane_id="${OPTARG}"
			;;
		k)
      # do not change !!! 
      provider_name="${OPTARG}"
			;;
		i)
      # do not change !!! 
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
  "optionsnotify")
    # Will be called when options are set
    # If not needed just exit 0
    _optionsnotify "$pane_id" "$provider_name" "$provider_value"
    exit 0
    ;;
  *)
    echo >&2 "Invalid action '${action}'"
    exit 1
    ;;
esac
}
main "$@"
