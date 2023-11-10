#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/exported.sh"

main() {
  local module_to_change
  local loaded_modules="$(get_tmux_option "@penmux-loaded-modules" "")"
  local session="$(tmux display-message -p "#{session_id}")"
  local module_path
  local module_name
  local option
  local opt_type
  local value
  local err

  if [ -z "$loaded_modules" ]; then
    tmux display-message -d 5000 "No modules loaded"
    return
  fi

  module_to_change="$("$CURRENT_DIR/_modules.sh" -a select_loaded)"
  [ -z "$module_to_change" ] && exit 0

  module_path="$(penmux_module_convert_relative_path "$module_to_change")"

  module_name="$(penmux_module_get_name "$module_path")"

  option="$("$CURRENT_DIR/_modules.sh" -a select_option -m "$module_to_change")"
  [ -z "$option" ] && exit 0

  value="$(penmux_module_get_option "$module_path" "$option")"

  opt_type="$(penmux_module_get_option_type "$module_path" "$option")"
  [ -z "$opt_type" ] && exit 0

  case "$opt_type" in
    "OptionTypeBool")
      tmux display-menu -T "Change '$option' for '$module_name'" \
        "true" "t" \
        "run-shell '\"$CURRENT_DIR/_modules.sh\" -a set_option -m \"$module_path\" -o \"$option\" -v \"true\"'" \
        "false" "f" \
        "run-shell '\"$CURRENT_DIR/_modules.sh\" -a set_option -m \"$module_path\" -o \"$option\" -v \"false\"'" \
        "unset" "u" \
        "run-shell '\"$CURRENT_DIR/_modules.sh\" -a set_option -m \"$module_path\" -o \"$option\" -v \"\"'"
      ;;
    "OptionTypeString")
      tmux command-prompt -p "Change '$option' for '$module_name': " -I "$value" "run-shell '\"$CURRENT_DIR/_modules.sh\" -a set_option -m \"$module_path\" -o \"$option\" -v \"%%\"'"
      ;;
    "OptionTypeInt")
      tmux command-prompt -p "Change '$option' for '$module_name': " -I "$value" "run-shell '\"$CURRENT_DIR/_modules.sh\" -a set_option -m \"$module_path\" -o \"$option\" -v \"%%\"'"
      ;;
    *)
      exit 1
      ;;
  esac
}
main
