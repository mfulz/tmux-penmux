#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/../include/variables.sh"
source "$CURRENT_DIR/../penmux/inc.sh"

main() {
  local module_to_load="$1"
  local loaded_modules="$(_module_get_loaded)"
  local cmds="$(get_tmux_option "@penmux-default-cmds" "" "")"
  local session="$(tmux display-message -p "#{session_id}")"
  local module_path
  local cmdprio
  local err

  # dirty hack to set hooks for plugin
  # "$CURRENT_DIR/internal/init_hooks.sh"

  echo "LOOOOOOO $module_to_load" >> /tmp/penmux

  [[ -z "$module_to_load" ]] && module_to_load="$("$CURRENT_DIR/internal/modules.sh" -a select)"
  [[ -z "$module_to_load" ]] && exit 0

  echo "LOOOOOOO $module_to_load" >> /tmp/penmux
  while IFS= read -r m; do
    if [[ "$m" == "$module_to_load" ]]; then
      tmux display-message -d 5000 "Module '$module_to_load' already loaded"
      return
    fi
  done <<< "$loaded_modules"

  module_path="$(_module_convert_relative_path "$module_to_load")"

  cmdprio="$(_module_get_cmdprio "$module_path")"
  if [ -n "$cmdprio" ]; then
    local new_cmds=""
    local cmd_script="$module_path:$cmdprio"
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

  # PreModuleLoad hooking
  _module_run_hook "PreModuleLoad" "$module_to_load"

  err="$("$CURRENT_DIR/internal/handler.sh" "$module_path" -a load 2>&1 1>/dev/null)" || {
    tmux display-message -d 5000 "Module load error: '$err'"
    return
  }

  local module_keytable_file="$(_keytables_get_file "$module_path")"
  if [[ -n "$module_keytable_file" ]]; then
    local module_name="$(_module_get_name "$module_path")"
    local prefix_key="$(_keytables_get_prefixkey "$module_keytable_file")"
    local keytable_name="penmux_module_${module_name}_keytable"
    local keys="$(_keytables_get_keys "$module_keytable_file")"

    tmux bind -T penmux_keytable "$prefix_key" switch-client -T "$keytable_name"
    while IFS= read -r k; do
      local key_func="$(_keytables_get_key_func "$module_keytable_file" "$k")"
      tmux bind -T "$keytable_name" "$k" "run-shell '\"$CURRENT_DIR/internal/handler.sh\" \"$module_path\" -a keyfunc -f \"$key_func\"'"
    done <<< "$keys"
  fi

  tmux display-message -d 5000 "Module '$module_to_load' loaded"

  if [ -z "$loaded_modules" ]; then
    tmux set-option -a "@penmux-loaded-modules" "$module_to_load"
  else
    tmux set-option -a "@penmux-loaded-modules" "#$module_to_load"
  fi
  
  # PostModuleLoad hooking
  _module_run_hook "PostModuleLoad" "$module_to_load" "$module_to_load"
}
main "$@"
