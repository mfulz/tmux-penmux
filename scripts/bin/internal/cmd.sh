#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/../../include/variables.sh"
source "$CURRENT_DIR/../../penmux/inc.sh"

main() {
  local calling_pane_id="$1"
  local cmds="$(get_tmux_option "@penmux-default-cmds" "" "")"
  local pane_id="$(tmux display-message -p "#D")"
  local session="$(tmux display-message -p "#{session_id}")"

  if [ -z "$cmds" ]; then
    $SHELL
  else
    local to_run
    for c in $cmds; do
      local len=${#c}
      local idx_mpath=$(echo "$c" | grep -bo : | cut -d: -f1 | head -n1)
      local idx_prio=$(echo "$c" | grep -bo : | cut -d: -f1 | tail -n1)
      local mpath="${c:0:$idx_mpath}"
      local handle_script="${c:$((idx_prio+1)):$len}"
      if [ -z "$to_run" ]; then
        to_run="$CURRENT_DIR/handler.sh $mpath -a cmd -p $pane_id -c $calling_pane_id"
      else
        to_run="$to_run; $CURRENT_DIR/handler.sh $mpath -a cmd -p $pane_id -c $calling_pane_id"
      fi
    done
    echo "$to_run" >> /tmp/to_run

    tmux run-shell -t "$pane_id" "$to_run"
  fi
}
main "$@"
