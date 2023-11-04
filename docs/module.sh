#!/usr/bin/env bash

### Module handle script ###
# Has to be implemented by every module

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_MODULE_PATH=""

main() {
	local action
  local penmux_scripts

	local OPTIND o
	while getopts "a:vc:m:" o; do
		case "${o}" in
		a)
			action="${OPTARG}"
			;;
		v)
      echo "1"
      exit 0
			;;
		c)
      penmux_scripts="${OPTARG}"
			;;
		m)
      _MODULE_PATH="${OPTARG}"
			;;
    *)
      echo >&2 "Invalid parameter"
      exit 1
      ;;
  esac
done

source "${penmux_scripts}/variables.sh"
source "${penmux_scripts}/helpers.sh"

case "${action}" in
  "load")
    # Will be called on module load
    # Used for initialization stuff
    # If not needed just exit 0
    exit 0
    ;;
  "unload")
    # Will be called on module unload
    # Used for cleanup stuff
    # If not needed just exit 0
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
