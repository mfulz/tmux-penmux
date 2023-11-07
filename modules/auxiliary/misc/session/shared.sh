_get_new_session_dir() {
  local pane_id="$1"
  local session_name="$2"
  local use_cwd="$(penmux_module_get_option "$_MODULE_PATH" "UseCwd")"
  local session_dir="$(penmux_module_get_option "$_MODULE_PATH" "SessionDir")"
  local final_session_dir
  local pwd

  if [ -z "$session_name" ]; then
    session_name="$(tmux display-message -p "#S")"
  fi

  if [[ "$use_cwd" == "true" ]]; then
    pwd="$(tmux display-message -p -t "$pane_id" "#{pane_current_path}")"
    final_session_dir="$pwd/$session_name"
  else
    final_session_dir="$session_dir/$session_name"
  fi

  expand_tmux_format_path "$pane_id" "$final_session_dir"
}
