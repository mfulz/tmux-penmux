#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/exported.sh"

main() {
  local module_to_unload
  local new_modules
  local loaded_modules="$(get_tmux_option "@penmux-loaded-modules" "")"
  local cmds="$(get_tmux_option "@penmux-default-cmds" "" "")"
  local session="$(tmux display-message -p "#{session_id}")"
  local handle_script
  local module_path
  local err

  if [ -z "$loaded_modules" ]; then
    tmux display-message -d 5000 "No modules loaded"
    return
  fi

  module_to_unload="$("$CURRENT_DIR/_modules.sh" -a select_loaded)"
  [ -z "$module_to_unload" ] && exit 0

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

  cmdprio="$(penmux_module_get_cmdprio "$module_path")"
  if [ -n "$cmdprio" ]; then
    local new_cmds=""
    if [ -n "$cmds" ]; then
      local removed=""
      for c in $cmds; do
        if [ -n "$removed" ]; then
          new_cmds="$new_cmds $c"
          continue
        fi

        local idx_mpath=$(echo "$c" | grep -bo : | cut -d: -f1 | head -n1)
        local mpath="${c:0:$((idx_mpath))}"
        if [[ "$mpath" == "$module_path" ]]; then
          removed="1"
        else
          if [ -z "$new_cmds" ]; then
            new_cmds="$c"
          else
            new_cmds="$new_cmds $c"
          fi
        fi
      done
    fi

    tmux set-option -t "$session" "@penmux-default-cmds" "$new_cmds"
  fi

  err="$($handle_script -c "$CURRENT_DIR" -a unload -m "$module_path")" || {
    tmux display-message -d 5000 "Module unload error: '$err'"
      return
    }
  }
  main
