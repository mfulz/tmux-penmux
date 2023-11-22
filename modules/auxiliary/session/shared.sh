_get_new_session_dir() {
  local pane_id="$1"
  local session_name="$2"
  local use_cwd="$(penmux_module_get_option "$_MODULE_PATH" "UseCwd")"
  local session_dir="$(penmux_module_get_option "$_MODULE_PATH" "SessionDirBase")"
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

  penmux_expand_tmux_format_path "$pane_id" "$final_session_dir"
}

_session_file_to_array() {
  local session_file="$1"
  local session_arr
  declare -A session_arr

  [[ -e "$session_file" ]] || return 1

  while IFS= read -r l; do
    local key="$(echo "$l" | cut -d, -f1)"
    local val="$(echo "$l" | cut -d, -f2-)"

    session_arr["$key"]="$val"
  done < "$session_file"

  echo "${session_arr[@]@K}"
}

_array_to_session_file() {
  local session_file="$1"
  local -n session_arr=$2

  [[ -e "$session_file" ]] && rm "$session_file"

  for key in "${!session_arr[@]}"; do
    printf "%s,%s\n" "$key" "${session_arr[${key}]}" >> "$session_file"
  done
}

_unset_session() {
  local pane_id="$1"
  local session_opts

  declare -A session_opts="($(penmux_module_get_exported_options "$pane_id"))"

  for key in "${!session_opts[@]}"; do
    tmux set-option -p -t "$pane_id" -u "$key"
  done
}
