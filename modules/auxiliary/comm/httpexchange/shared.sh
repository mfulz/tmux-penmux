_get_root_dir() {
  local pane_id="$1"
  local use_session_dir="$(penmux_module_get_option "$_MODULE_PATH" "UseSessionDir" "$pane_id")"
  local root_dir_base="$(penmux_module_get_option "$_MODULE_PATH" "HttpRootDirBase" "$pane_id")"
  local root_dir="$root_dir_base/http_root"
  local root_dir_session


  if [[ "$use_session_dir" == "true" ]]; then
    root_dir_session="$(penmux_module_get_option "$_MODULE_PATH" "SessionDir" "$pane_id")"
    if [[ -n "$root_dir_session" ]]; then
      root_dir="$root_dir_session/http_root"
    fi
  fi

  penmux_expand_tmux_format_path "$pane_id" "$root_dir"
}

_expand_cmd_string() {
  local input="${1}"
  local pane_id="${2}"
  local file="${3}"
  local filename="$(basename "$file")"

  input="${input/"##fileName##"/${filename}}"
  input="${input/"##file##"/${file}}"

  echo "$input"
}
