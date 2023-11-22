#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/../include/variables.sh"
source "$CURRENT_DIR/../penmux/inc.sh"

main() {
  local module_to_run
  local loaded_modules="$(_module_get_loaded)"
  local pane_id="$(tmux display-message -p "#D")"
  local module_path
  local err

  module_to_run="$("$CURRENT_DIR/internal/modules.sh" -a select_runnable -l "Select Module to run")"
  [ -z "$module_to_run" ] && exit 0

  module_path="$(_module_convert_relative_path "$module_to_run")"

  err="$($CURRENT_DIR/internal/handler.sh "$module_path" -a run -p "$pane_id" 2>&1 1>/dev/null)" || {
    tmux display-message -d 5000 "Module run error: '$err'"
    return
  }
}
main
