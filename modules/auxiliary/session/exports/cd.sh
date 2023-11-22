#!/usr/bin/env bash

cd_session() {
  local session_file 

  if [ -z "$1" ]; then
    cd || return
  else
    cd "$1" || return
  fi

  if [ -e ".pmses" ]; then
    session_file="$(realpath .pmses)"
    tmux run-shell "\"$HOME/.tmux/plugins/tmux-penmux/modules/auxiliary/session/session.sh\" -a load -m \"$HOME/.tmux/plugins/tmux-penmux/modules/auxiliary/session.xml\" -c \"$HOME/.tmux/plugins/tmux-penmux/scripts/penmux\" -f \"$session_file\""
  fi
}
