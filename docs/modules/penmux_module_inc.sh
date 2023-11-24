#!/usr/bin/env bash

### Module handle script ###
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
