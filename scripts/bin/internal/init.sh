#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/../../include/variables.sh"
source "$CURRENT_DIR/../../penmux/inc.sh"

main() {
  local pane_id="$(tmux display-message -p "#D")"
  local session="$(tmux display-message -p "#{session_id}")"
  local initialized="$(get_tmux_option "@penmux-initialized" "" "")"
  local autoload_modules_option_value="$(get_tmux_option "$autoload_modules_option" "$default_autoload_modules")"

  if [ -z "$initialized" ]; then
    # autoload modules
    for m in $autoload_modules_option_value; do
      tmux run-shell "\"$CURRENT_DIR/../load_module.sh\" \"$m\""
    done

    tmux set-option -t "$session" default-command "\"$CURRENT_DIR/cmd.sh\" \"$pane_id\""
    tmux set-hook -t "$session" -a after-select-pane "run-shell \"$CURRENT_DIR/update_default_cmd.sh\""
    tmux set-hook -t "$session" -a after-split-window "run-shell \"$CURRENT_DIR/update_default_cmd.sh\""
    tmux set-hook -t "$session" -a after-select-window "run-shell \"$CURRENT_DIR/update_default_cmd.sh\""
    tmux set-hook -t "$session" -a after-new-window "run-shell \"$CURRENT_DIR/update_default_cmd.sh\""
    tmux set-hook -t "$session" -a pane-focus-in "run-shell \"$CURRENT_DIR/update_default_cmd.sh\""

    tmux set-option -t "$session" "@penmux-initialized" "1"
  fi
}
main
