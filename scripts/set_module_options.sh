#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/helpers.sh"

main() {
  local module_to_change
  local loaded_modules="$(get_tmux_option "@penmux-loaded-modules" "")"
  local session="$(tmux display-message -p "#{session_id}")"
  local option
  local value
  local err

  if [ -z "$loaded_modules" ]; then
    tmux display-message -d 5000 "No modules loaded"
    return
  fi

  module_to_change="$("$CURRENT_DIR/_modules.sh" -a select_loaded)"
  [ -z "$module_to_change" ] && exit 0

  option="$("$CURRENT_DIR/_modules.sh" -a select_option -m \"$module_to_change\")"
  [ -z "$option" ] && exit 0

  value="$(tmux command-prompt -p "Enter Value for "$option": " "display-message -p '%%'")"
  penmux_module_set_option "$(penmux_module_convert_relative_path "$module_to_change")" "$option" "$value"
}
  main
