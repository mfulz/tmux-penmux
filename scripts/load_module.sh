#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/helpers.sh"

main() {
  local module_to_load
  local loaded_modules="$(penmux_module_get_loaded)"
  local handle_script
  local module_path
  local err
  module_to_load="$("$CURRENT_DIR/_modules.sh" -a select)"

  while IFS= read -r m; do
    if [[ "$m" == "$module_to_load" ]]; then
      tmux display-message -d 5000 "Module '$module_to_load' already loaded"
      return
    fi
  done <<< "$loaded_modules"

  module_path="$(penmux_module_convert_relative_path "$module_to_load")"

  handle_script="$(penmux_module_get_handlescript "$module_path")"
  if [ -z "$handle_script" ]; then
      tmux display-message -d 5000 "Module handle script missing in xml"
      return
  fi

  handle_script="$_PENMUX_MODULE_DIR/$handle_script"
  if [ ! -e "$handle_script" ]; then
      tmux display-message -d 5000 "Module handle script not found"
      return
  fi

  err="$($handle_script -c "$CURRENT_DIR" -a load -m "$module_path")" || {
      tmux display-message -d 5000 "Module load error: '$err'"
      return
  }

  if [ -z "$loaded_modules" ]; then
    tmux set-option -a "@penmux-loaded-modules" "$module_to_load"
  else
    tmux set-option -a "@penmux-loaded-modules" "#$module_to_load"
  fi
}
main
