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
  local clipboard_command="$(penmux_module_get_option "$_MODULE_FILE" "ClipboardCommand" "$pane_id")"
  local csv
  local snippet
  local cp_win

  csv="$("$_PENMUX_INC_CURRENT_DIR/snipper.sh" -a select_csv -c "$_PENMUX_SCRIPTS" -m "$_MODULE_FILE" -p "$pane_id")"
  [[ -z "$csv" ]] && return

  snippet="$("$_PENMUX_INC_CURRENT_DIR/snipper.sh" -a select_snippet -c "$_PENMUX_SCRIPTS" -m "$_MODULE_FILE" -p "$pane_id" -f "$csv")"
  [[ -z "$snippet" ]] && return

  clipboard_command="${clipboard_command/"\$\$snippet\$\$"/"${snippet}"}"

  cp_win="$(tmux new-window -d -P "$SHELL")"
  tmux send-keys -t "$cp_win" " $clipboard_command" Enter
  tmux display-message -d 5000 "Snippet copied to clipboard"
  tmux send-keys -t "$cp_win" " exit" Enter
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
