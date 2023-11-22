#!/usr/bin/env bash

### Module handle script ###
# Has to be implemented by every module

_PENMUX_INC_CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$_PENMUX_INC_CURRENT_DIR/shared.sh"

_load() {
  return
}

_unload() {
  return
}

_run() {
  local pane_id="$1"
  local no_confirm="$(penmux_module_get_option "$_MODULE_FILE" "NoConfirm" "$pane_id")"
  local running="$(penmux_module_get_option "$_MODULE_FILE" "HttpRunning" "$pane_id")"
  local host="$(penmux_module_get_option "$_MODULE_FILE" "HttpHost" "$pane_id")"
  local port="$(penmux_module_get_option "$_MODULE_FILE" "HttpPort" "$pane_id")"
  local dir="$(_get_root_dir "$pane_id")"
  local file
  local csv
  local cmd


  if [[ "$running" != "true" ]]; then
    if [[ ! -d "$dir" ]]; then
      mkdir -p "$dir" || return
    fi

    tmux send-keys "reset" Enter
    tmux send-keys "python -m http.server -b \"$host\" -d \"$dir\" \"$port\" 2>&1 1>/dev/null && \"$_PENMUX_INC_CURRENT_DIR/httpexchange.sh\" -a stopped -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_FILE\" -p \"$pane_id\"" Enter
    penmux_module_set_option "$_MODULE_FILE" "HttpRunning" "true" "$pane_id"
    penmux_module_set_option "$_MODULE_FILE" "HttpRootDir" "$dir/" "$pane_id"
    penmux_module_set_option "$_MODULE_FILE" "HttpUri" "http://$host:$port/" "$pane_id"
  else
    file="$("$_PENMUX_INC_CURRENT_DIR/httpexchange.sh" -a select_file -c "$_PENMUX_SCRIPTS" -m "$_MODULE_FILE" -p "$pane_id")"
    [[ -z "$file" ]] && return

    csv="$("$_PENMUX_INC_CURRENT_DIR/httpexchange.sh" -a select_csv -c "$_PENMUX_SCRIPTS" -m "$_MODULE_FILE" -p "$pane_id")"
    [[ -z "$csv" ]] && return

    cmd="$("$_PENMUX_INC_CURRENT_DIR/httpexchange.sh" -a select_cmd -c "$_PENMUX_SCRIPTS" -m "$_MODULE_FILE" -p "$pane_id" -f "$csv" -d "$file")"

    if [[ "$no_confirm" == "true" ]]; then
      tmux send-keys "$cmd" Enter
    else
      tmux send-keys "$cmd"
    fi
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
