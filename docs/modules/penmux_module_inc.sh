#!/usr/bin/env bash

### Module handler interface ###
# Has to be implemented by every module

_PENMUX_INC_CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Basic suggestion to used module shared functions
#source "$_PENMUX_INC_CURRENT_DIR/shared.sh"

# _PENMUX_SCRIPTS will point to full path of script/penmux (can be used for sourcing inc.sh)
# _MODULE_FILE will point to full path of the module xml file

_load() {
  return
}

_unload() {
  return
}

_run() {
  local "$pane_id"

  return
}

_cmd() {
  local calling_pane_id="$1"
  local pane_id="$2"

  return
}

_optionsnotify() {
  local pane_id="$1"
  local opt="$2"
  local val="$3"
  local volatile="$4"

  return
}

# @description This function is used to retrieve values for an option
# of type OptionTypeSelection that can be set.
#
# @arg $1 string The ID of the tmux pane which requested the values
# @arg $2 string The name of the option which values are requested
#
# @stdout list of value description pairs separated by ###: optionval1###val1 does the following\noptionval2###val2 does cool things
_optionvalues() {
  local pane_id="$1"
  local opt="$2"

  return
}

_consumes() {
  local pane_id="$1"
  local opt="$2"
  local val="$3"

  return
}

_keyfunc() {
  local calling_pane_id="$1"
  local pane_id="$2"
  lcoal func_name="$3"

  case "$func_name" in
    *)
      echo >&2 "Unknown func name: '$func_name'"
      ;;
  esac

  return
}

_hook() {
  local pane_id="$1"
  local hook="$2"
  local hook_option="$3"

  case "$hook" in
    "PreModuleLoad")
      ;;
    "PostModuleLoad")
      ;;
    "PreModuleUnload")
      ;;
    "PostModuleUnload")
      ;;
    *)
      echo >&2 "Unknown hook name: '$hook'"
      ;;
  esac

  return
}

_apiver() {
  # do not change this without implementing the
  # required changes
  echo "1.0.0"
}
