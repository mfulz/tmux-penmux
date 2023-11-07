_get_log_dir() {
  local pane_id="$1"
  local log_penmux_session_dir="$(penmux_module_get_option "$_MODULE_PATH" "LogPenmuxSessionDir")"
  local logdir="$(penmux_module_get_option "$_MODULE_PATH" "LogDir")"
  local logdir_penmux_session


  if [[ "$log_penmux_session_dir" == "true" ]]; then
    logdir_penmux_session="$(get_tmux_option "@penmux-session-dir" "" "$pane_id")"
    if [[ -n "$logdir_penmux_session" ]]; then
      logdir="$logdir_penmux_session"
    fi
  fi

  expand_tmux_format_path "$pane_id" "$logdir"
}

_get_log_file() {
  local pane_id="$1"
  local logdir="$(_get_log_dir "$pane_id")"
  local logfile="$(penmux_module_get_option "$_MODULE_PATH" "Name")"
  logfile="$(expand_tmux_format_path "$pane_id" "$logdir/$logfile")"

  # quickfix for handling pane title
  # TODO: correct handling
  logfile="${logfile/" (logging)"/}"

  echo "$logfile"
}

_get_act_log_file() {
  local pane_id="$1"
  local act_logfile="$(tmux show-option -t "${pane_id}" -pqv "@penmux-scriptlog-logfile")"
  echo "$act_logfile"
}

_is_logging() {
  local pane_id="$1"
  local current_pane_logging="$(tmux show-option -t "${pane_id}" -pqv "@penmux-scriptlog-logfile")"
	[ -n "$current_pane_logging" ]
}

_get_all_windows() {
  tmux list-windows -F \#I
}

_get_all_panes() {
  tmux list-panes -F \#D
}
