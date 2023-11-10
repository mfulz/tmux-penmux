#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/helpers.sh"

main() {
  local module_to_load
  local loaded_modules="$(penmux_module_get_loaded)"
  local cmds="$(get_tmux_option "@penmux-default-cmds" "" "")"
  local session="$(tmux display-message -p "#{session_id}")"
  local handle_script
  local module_path
  local cmdprio
  local err

  # dirty hack to set hooks for plugin
  "$CURRENT_DIR/init_hooks.sh"

  module_to_load="$("$CURRENT_DIR/_modules.sh" -a select)"
  [ -z "$module_to_load" ] && exit 0

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

  cmdprio="$(penmux_module_get_cmdprio "$module_path")"
  if [ -n "$cmdprio" ]; then
    local new_cmds=""
    local cmd_script="$module_path:$cmdprio:$handle_script"
    if [ -z "$cmds" ]; then
      new_cmds="$cmd_script"
    else
      local added=""
      for c in $cmds; do
        if [ -n "$added" ]; then
          new_cmds="$new_cmds $c"
          continue
        fi

        local idx_mpath=$(echo "$c" | grep -bo : | cut -d: -f1 | head -n1)
        local idx_prio=$(echo "$c" | grep -bo : | cut -d: -f1 | tail -n1)
        local c_prio="${c:$((idx_mpath+1)):$((idx_prio-idx_mpath-1))}"
        if [ "$cmdprio" -lt "$c_prio" ]; then
          if [ -z "$new_cmds" ]; then
            new_cmds="$cmd_script"
            new_cmds="$new_cmds $c"
          else
            new_cmds="$new_cmds $cmd_script $c"
          fi
          added="1"
        else
          if [ -z "$new_cmds" ]; then
            new_cmds="$c"
          else
            new_cmds="$new_cmds $c"
          fi
        fi
      done

      if [ -z "$added" ]; then
        new_cmds="$new_cmds $cmd_script"
      fi
    fi

    tmux set-option -t "$session" "@penmux-default-cmds" "$new_cmds"
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
