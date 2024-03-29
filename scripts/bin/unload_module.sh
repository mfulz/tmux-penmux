#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/../include/variables.sh"
source "$CURRENT_DIR/../penmux/inc.sh"

main() {
  local module_to_unload
  local new_modules
  local loaded_modules="$(get_tmux_option "@penmux-loaded-modules" "")"
  local cmds="$(get_tmux_option "@penmux-default-cmds" "" "")"
  local session="$(tmux display-message -p "#{session_id}")"
  local module_path
  local err

  if [ -z "$loaded_modules" ]; then
    tmux display-message -d 5000 "No modules loaded"
    return
  fi

  module_to_unload="$("$CURRENT_DIR/internal/modules.sh" -a select_loaded)"
  [ -z "$module_to_unload" ] && exit 0

  new_modules="${loaded_modules/\#$module_to_unload/}"
  new_modules="${new_modules/$module_to_unload\#/}"
  new_modules="${new_modules/$module_to_unload/}"

  tmux set-option "@penmux-loaded-modules" "$new_modules"

  module_path="$(_module_convert_relative_path "$module_to_unload")"

  # PreModuleUnload hooking
  _module_run_hook "PreModuleUnload" "$module_to_unload"

  local module_keytable_file="$(_keytables_get_file "$module_path")"
  if [[ -n "$module_keytable_file" ]]; then
    local module_name="$(_module_get_name "$module_path")"
    local prefix_key="$(_keytables_get_prefixkey "$module_keytable_file")"
    local keytable_name="penmux_module_${module_name}_keytable"
    local keys="$(_keytables_get_keys "$module_keytable_file")"

    while IFS= read -r k; do
      tmux unbind -T "$keytable_name" "$k"
    done <<< "$keys"
    tmux unbind -T penmux_keytable "$prefix_key"
  fi

  cmdprio="$(_module_get_cmdprio "$module_path")"
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

  err="$($CURRENT_DIR/internal/handler.sh "$module_path" -a unload)" || {
    tmux display-message -d 5000 "Module unload error: '$err'"
    return
  }
  tmux display-message -d 5000 "Module '$module_to_unload' unloaded"

  # PostModuleUnload hooking
  _module_run_hook "PostModuleUnload" "$module_to_unload"
}
main
