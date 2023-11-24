#!/usr/bin/env bash

### Module handle script ###
# Has to be implemented by every module

_PENMUX_INC_CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# source "$_PENMUX_INC_CURRENT_DIR/shared.sh"

_load() {
  return
}

_unload() {
  return
}

_run() {
  local pane_id="$1"
  local no_confirm="$(penmux_module_get_option "$_MODULE_FILE" "NoConfirm" "$pane_id")"
  local csv
  local cmd

  csv="$("$_PENMUX_INC_CURRENT_DIR/commander.sh" -a select_csv -c "$_PENMUX_SCRIPTS" -m "$_MODULE_FILE" -p "$pane_id")"
  [[ -z "$csv" ]] && return

  if [[ "$csv" == *.sh ]]; then
    local command_search_path="$(penmux_module_get_option "$_MODULE_FILE" "CommandSearchPath" "$pane_id")"
    local cmd_file="$(penmux_expand_tmux_format_path "$pane_id" "$command_search_path/$csv")"

    "$cmd_file" -a run -c "$_PENMUX_SCRIPTS" -m "$_MODULE_FILE" -p "$pane_id"
    return
  fi

  cmd="$("$_PENMUX_INC_CURRENT_DIR/commander.sh" -a select_cmd -c "$_PENMUX_SCRIPTS" -m "$_MODULE_FILE" -p "$pane_id" -f "$csv")"

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
