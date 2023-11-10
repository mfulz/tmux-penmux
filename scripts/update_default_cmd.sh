#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/exported.sh"

main() {
  local pane_id="$(tmux display-message -p "#D")"
  local session="$(tmux display-message -p "#{session_id}")"

  tmux set-option -t "$session" default-command "\"$CURRENT_DIR/cmd.sh\" \"$pane_id\""
}
main
