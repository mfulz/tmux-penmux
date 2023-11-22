#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/../include/variables.sh"
source "$CURRENT_DIR/../include/exported.sh"

main() {
  local module_to_run
  local loaded_modules="$(_module_get_loaded)"
  local pane_id="$(tmux display-message -p "#D")"
  local handle_script
  local module_path
  local err

  module_to_run="$("$CURRENT_DIR/_modules.sh" -a select_runnable -l "Select Module to run")"
  [ -z "$module_to_run" ] && exit 0

  module_path="$(_module_convert_relative_path "$module_to_run")"

  handle_script="$(_module_get_handlescript "$module_path")"
  if [ -z "$handle_script" ]; then
      tmux display-message -d 5000 "Module handle script missing in xml"
      return
  fi

  handle_script="$_PENMUX_MODULE_DIR/$handle_script"
  if [ ! -e "$handle_script" ]; then
      tmux display-message -d 5000 "Module handle script not found"
      return
  fi

  err="$($handle_script -a run -c "$CURRENT_DIR/../include" -m "$module_path" -p "$pane_id" 2>&1 1>/dev/null)" || {
    tmux display-message -d 5000 "Module run error: '$err'"
    return
  }
}
main
