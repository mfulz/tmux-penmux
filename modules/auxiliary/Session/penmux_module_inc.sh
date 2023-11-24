#!/usr/bin/env bash

### Module handle script ###
# Has to be implemented by every module

_PENMUX_INC_CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$_PENMUX_INC_CURRENT_DIR/shared.sh"

_load() {
  local session="$(tmux display-message -p "#{session_id}")"
  local session_name="$(tmux display-message -p "#{S}")"
  local panes="$(tmux list-panes -s -t "$session" -F "#D")"

  while IFS= read -r p; do
    tmux set-option -t "$p" automatic-rename-format '#{?#{==:#{@penmux-Session-SessionName},},No Session,#{@penmux-Session-SessionName}} (#{?#{==:#{@penmux-Session-SessionDir},},CWD: #{pane_current_path},CSD: #{@penmux-Session-SessionDir}})'
    tmux set-option -t "$p" status-interval 5
    tmux set-option -t "$p" automatic-rename on
  done <<< "$panes"
}

_unload() {
  local session="$(tmux display-message -p "#{session_id}")"
  local session_name="$(tmux display-message -p "#{S}")"
  local panes="$(tmux list-panes -s -t "$session" -F "#D")"

  while IFS= read -r p; do
    tmux run-shell "\"$_PENMUX_INC_CURRENT_DIR/session.sh\" -a stop -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_FILE\" -p \"$p\""

    tmux set-option -t "$p" -u automatic-rename-format
    tmux set-option -t "$p" -u status-interval
    tmux set-option -t "$p" -u automatic-rename
  done <<< "$panes"
}

_cmd() {
  local calling_pane_id="$1"
  local pane_id="$2"
  local session_name="$(penmux_module_get_option "$_MODULE_FILE" "SessionName" "$calling_pane_id")"
  local session_dir="$(penmux_module_get_option "$_MODULE_FILE" "SessionDir" "$calling_pane_id")"
  local session_opts

  if [ -n "$session_name" ] && [ -n "$session_dir" ]; then
    penmux_module_set_option "$_MODULE_FILE" "SessionName" "$session_name" "$pane_id"
    penmux_module_set_option "$_MODULE_FILE" "SessionDir" "$session_dir/" "$pane_id"

    penmux_module_copy_exported_options "$pane_id" "$calling_pane_id"

    tmux respawn-pane -k -t "$pane_id" -c "$session_dir" "$SHELL -c ' cd . && $SHELL'"
    # dirty hack (dunno what's wrong here)
    # TODO:Fix
    # tmux send-keys " cd . && reset" Enter

    penmux_module_notify_consumers "$_MODULE_FILE" "SessionName" "$pane_id"
    penmux_module_notify_consumers "$_MODULE_FILE" "SessionDir" "$pane_id"
  else
    tmux respawn-pane -k -t "$pane_id" "$SHELL"
  fi

  tmux set-option automatic-rename-format '#{?#{==:#{@penmux-Session-SessionName},},No Session,#{@penmux-Session-SessionName}} (#{?#{==:#{@penmux-Session-SessionDir},},CWD: #{pane_current_path},CSD: #{@penmux-Session-SessionDir}})'
  tmux set-option status-interval 5
  tmux set-option automatic-rename on
}

_optionsnotify() {
  local pane_id="$1"
  local opt="$2"
  local val="$3"
  local volatile="$4"
  local session="$(tmux display-message -p "#{session_id}")"
  local panes="$(tmux list-panes -s -t "$session" -F "#D")"
  local session_name="$(penmux_module_get_option "$_MODULE_FILE" "SessionName" "$pane_id")"
  local session_dir="$(penmux_module_get_option "$_MODULE_FILE" "SessionDir" "$pane_id")"
  local session_file="$(realpath $session_dir/.pmses)"
  local auto_save="$(penmux_module_get_option "$_MODULE_FILE" "AutoSave")"
  local session_opts

  [[ "$opt" == "@penmux-SessionName" ]] && return
  [[ "$opt" == "@penmux-SessionDir" ]] && return

  if [ -n "$session_name" ] && [ -n "$session_dir" ]; then
    while IFS= read -r p; do
      local pane_session_name="$(penmux_module_get_option "$_MODULE_FILE" "SessionName" "$p")"
      local pane_session_dir="$(penmux_module_get_option "$_MODULE_FILE" "SessionDir" "$p")"

      if [[ "$session_name" == "$pane_session_name" ]] && [[ "$session_dir" == "$pane_session_dir" ]]; then
        if [ -z "$val" ]; then
          tmux set-option -t "$p" -u -p "$opt"
        else
          tmux set-option -t "$p" -p "$opt" "$val"
        fi
      fi
    done <<< "$panes"

    [[ "$auto_save" == "true" ]] || exit 0
    [[ "$volatile" == "true" ]] && exit 0
    declare -A session_opts="($(_session_file_to_array "$session_file"))"

    if [ -z "$val" ]; then
      unset "session_opts[${opt}]"
    else
      session_opts["${opt}"]="$val"
    fi

    _array_to_session_file "$session_file" session_opts
  fi
}

_keyfunc() {
  local calling_pane_id="$1"
  local pane_id="$2"
  lcoal func_name="$3"

  case "$func_name" in
    "new")
      "$_PENMUX_INC_CURRENT_DIR/session.sh" -a new -c "$_PENMUX_SCRIPTS" -m "$_MODULE_FILE"
      ;;
    "exit")
      "$_PENMUX_INC_CURRENT_DIR/session.sh" -a stop -c "$_PENMUX_SCRIPTS" -m "$_MODULE_FILE"
      ;;
    "load")
      "$_PENMUX_INC_CURRENT_DIR/session.sh" -a load -c "$_PENMUX_SCRIPTS" -m "$_MODULE_FILE"
      ;;
    "save")
      "$_PENMUX_INC_CURRENT_DIR/session.sh" -a save -c "$_PENMUX_SCRIPTS" -m "$_MODULE_FILE"
      ;;
    *)
      echo >&2 "Unknown func name: '$func_name'"
      ;;
  esac

  return
}

_hook() {
  local pane_id="$1"
  local hook="$2"
  local hook_option="$3"
  local session="$(tmux display-message -p "#{session_id}")"
  local panes="$(tmux list-panes -s -t "$session" -F "#D")"

  case "$hook" in
    "PreModuleLoad")
      ;;
    "PostModuleLoad")
      while IFS= read -r p; do
        "$_PENMUX_INC_CURRENT_DIR/session.sh" -a update -c "$_PENMUX_SCRIPTS" -m "$_MODULE_FILE" -p "$p"
      done <<< "$panes"
      ;;
    "PreModuleUnload")
      ;;
    "PostModuleUnload")
      ;;
    *)
      echo >&2 "Unknown hook name: '$hook'"
      ;;
  esac

  return
}

_apiver() {
  # do not change this without implementing the
  # required changes
  echo "1.0.0"
}
