#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/helpers.sh"

main() {
  local module_to_unload
  local new_modules
  local loaded_modules="$(get_tmux_option "@penmux-loaded-modules" "")"
  local handle_script
  local module_path
  local err

  if [ -z "$loaded_modules" ]; then
    tmux display-message -d 5000 "No modules loaded"
    return
  fi

  module_to_unload="$("$CURRENT_DIR/_modules.sh" -a select_loaded)"
  new_modules="${loaded_modules/\#$module_to_unload/}"
  new_modules="${new_modules/$module_to_unload\#/}"
  new_modules="${new_modules/$module_to_unload/}"

  tmux set-option "@penmux-loaded-modules" "$new_modules"

  module_path="$(penmux_module_convert_relative_path "$module_to_unload")"

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

  err="$($handle_script -c "$CURRENT_DIR" -a unload -m "$module_path")" || {
      tmux display-message -d 5000 "Module unload error: '$err'"
      return
  }
}
main
