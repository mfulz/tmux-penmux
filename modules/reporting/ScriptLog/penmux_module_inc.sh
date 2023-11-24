#!/usr/bin/env bash

### Module handle script ###
# Has to be implemented by every module

_PENMUX_INC_CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$_PENMUX_INC_CURRENT_DIR/shared.sh"

_load() {
  local session="$(tmux display-message -p "#{session_id}")"
  local logexisting="$(penmux_module_get_option "$_MODULE_FILE" "LogExisting")"
  local logdir
  local panes

  which script >/dev/null 2>&1 || {
    echo >&2 "Cannot find 'script'. Either it is not installed or not in path. Please make sure you have installed util-linux"
    exit 1
  }

  if [[ "$logexisting" == "true" ]]; then
    panes="$(tmux list-panes -s -t "$session" -F "#D")"
    while IFS= read -r p; do
      tmux run-shell -t "$p" "\"$_PENMUX_INC_CURRENT_DIR/scriptlog.sh\" -a start -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_FILE\" -p \"$p\""
    done <<< "$panes"
  fi
}

_unload() {
  local session="$(tmux display-message -p "#{session_id}")"
  local panes="$(tmux list-panes -s -t "$session" -F "#D")"

  while IFS= read -r p; do
    tmux run-shell -t "$p" "\"$_PENMUX_INC_CURRENT_DIR/scriptlog.sh\" -a revert -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_FILE\" -p \"$p\""
  done <<< "$panes"
}

_cmd() {
  local calling_pane_id="$1"
  local pane_id="$2"

  tmux run-shell -t "$pane_id" "\"$_PENMUX_INC_CURRENT_DIR/scriptlog.sh\" -a start -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_FILE\" -p \"$pane_id\""
}

_consumes() {
  local pane_id="$1"
  local provider_name="$2"
  local provider_value="$3"
  local session="$(tmux display-message -p "#{session_id}")"
  local panes="$(tmux list-panes -s -t "$session" -F "#D")"

  while IFS= read -r p; do
    tmux run-shell -t "$p" "\"$_PENMUX_INC_CURRENT_DIR/scriptlog.sh\" -a restart -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_FILE\" -p \"$p\""
  done <<< "$panes"
}

_hook() {
  local pane_id="$1"
  local hook="$2"
  local hook_option="$3"

  case "$hook" in
    "PreModuleLoad")
      ;;
    "PostModuleLoad")
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
