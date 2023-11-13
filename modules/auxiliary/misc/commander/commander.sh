#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PENMUX_SCRIPTS=""
_MODULE_PATH=""

# source "$CURRENT_DIR/shared.sh"

_list_csv() {
  local label="$1"
  local pane_id="$2"
  local command_search_path="$(penmux_module_get_option "$_MODULE_PATH" "CommandSearchPath" "$pane_id")"
  command_search_path="$(penmux_expand_tmux_format_path "$pane_id" "$command_search_path")"

  [[ -z "$label" ]] && label="Select commander definition file"

  tmux set-option -p @penmux-commander-hidden-csv "$(find "$command_search_path" -type f -iname "*\.csv" -printf '%P\n' | fzf --border-label="$label" --border="sharp" --cycle --preview="$CURRENT_DIR/commander.sh -a info_csv -c "$_PENMUX_SCRIPTS" -m "$_MODULE_PATH" -p "$pane_id" -f {}")"
}

_info_csv() {
  local csv="$1"
  local pane_id="$2"
  local command_search_path="$(penmux_module_get_option "$_MODULE_PATH" "CommandSearchPath" "$pane_id")"
  local csv_desc="$command_search_path/$(echo "$csv" | rev | cut -f 2- -d '.' | rev).desc"
  csv_desc="$(penmux_expand_tmux_format_path "$pane_id" "$csv_desc")"

  cat "$csv_desc"
}

_list_cmd() {
  local label="$1"
  local pane_id="$2"
  local csv_file="$3"
  local command_search_path="$(penmux_module_get_option "$_MODULE_PATH" "CommandSearchPath" "$pane_id")"
  csv_file="$command_search_path/$csv_file"
  csv_file="$(penmux_expand_tmux_format_path "$pane_id" "$csv_file")"
  local csv_content="$(cat "$csv_file")"
  local csv_arrays="$(penmux_csv_to_arrays "$csv_content")"
  local csv_names
  local csv_first="1"
  local cmd

  while IFS= read -r l; do
    if [[ -n "$csv_first" ]]; then
      csv_first=""
      continue
    else
      local csv_entry
      declare -A csv_entry="($(echo "$l"))"
      if [[ -z "$csv_names" ]]; then
        csv_names="$(printf "%s" "${csv_entry["name"]}")"
      else
        csv_names="$(printf "%s\n%s" "$csv_names" "${csv_entry["name"]}")"
      fi
    fi
  done <<< "$csv_arrays"

  [[ -z "$label" ]] && label="Select command"

  cmd="$(echo "$csv_names" | fzf --border-label="$label" --border="sharp" --cycle --preview="$CURRENT_DIR/commander.sh -a info_cmd -c "$_PENMUX_SCRIPTS" -m "$_MODULE_PATH" -p "$pane_id" -f "$csv_file" -s {}")"

  [[ -z "$cmd" ]] && return

  while IFS= read -r l; do
    local csv_entry
    local csv_command
    local csv_path
    declare -A csv_entry="($(echo "$l"))"

    if [[ "${csv_entry["name"]}" == "$cmd" ]]; then
      csv_command="$(penmux_module_expand_options_string "$_MODULE_PATH" "${csv_entry["command"]}" "$pane_id")"
      csv_command="$(penmux_expand_tmux_format_path "$pane_id" "$csv_command")"
      csv_path="$(penmux_module_expand_options_string "$_MODULE_PATH" "${csv_entry["path"]}" "$pane_id")"
      csv_path="$(penmux_expand_tmux_format_path "$pane_id" "$csv_path")"

      if [[ ! -d "$csv_path" ]]; then
        mkdir -p "$csv_path" || return
      fi

      tmux set-option -p @penmux-commander-hidden-cmd "$csv_command"
      return
    fi
  done <<< "$csv_arrays" 
}

_info_cmd() {
  local label="$1"
  local pane_id="$2"
  local csv_file="$3"
  local cmd="$4"
  local csv_content="$(cat "$csv_file")"
  local csv_arrays="$(penmux_csv_to_arrays "$csv_content")"

  while IFS= read -r l; do
    local csv_entry
    local csv_command
    declare -A csv_entry="($(echo "$l"))"

    if [[ "${csv_entry["name"]}" == "$cmd" ]]; then
      csv_command="$(penmux_module_expand_options_string "$_MODULE_PATH" "${csv_entry["command"]}" "$pane_id")"
      csv_command="$(penmux_expand_tmux_format_path "$pane_id" "$csv_command")"

      printf "Description: %s\n\nCommand: %s\n" "${csv_entry["description"]}" "$csv_command"
      return
    fi
  done <<< "$csv_arrays"
}

_select_csv() {
  local label="$1"
  local pane_id="$2"
  local csv

  tmux display-popup -w 80% -h 80% -E "$CURRENT_DIR/commander.sh -a list_csv -c \"$_PENMUX_SCRIPTS\" -l \"$label\" -m \"$_MODULE_PATH\" -p \"$pane_id\""
  csv="$(tmux show-options -pqv "@penmux-commander-hidden-csv")"
  tmux set-option -pu "@penmux-commander-hidden-csv" > /dev/null
  echo "${csv}"
}

_select_cmd() {
  local label="$1"
  local pane_id="$2"
  local csv="$3"
  local cmd

  tmux display-popup -w 80% -h 80% -E "$CURRENT_DIR/commander.sh -a list_cmd -c \"$_PENMUX_SCRIPTS\" -l \"$label\" -m \"$_MODULE_PATH\" -p \"$pane_id\" -f \"$csv\""
  cmd="$(tmux show-options -pqv "@penmux-commander-hidden-cmd")"
  tmux set-option -pu "@penmux-commander-hidden-cmd" > /dev/null
  echo "${cmd}"
}

main() {
  local action
  local pane_id
  local csv_file
  local label
  local cmd
  local err

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
      f)
        csv_file="${OPTARG}"
        ;;
      l)
        label="${OPTARG}"
        ;;
      s)
        cmd="${OPTARG}"
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
    "list_csv")
      _list_csv "$label" "$pane_id"
      exit 0
      ;;
    "select_csv")
      _select_csv "$label" "$pane_id"
      exit 0
      ;;
    "info_csv")
      _info_csv "$csv_file" "$pane_id"
      exit 0
      ;;
    "list_cmd")
      _list_cmd "$label" "$pane_id" "$csv_file"
      exit 0
      ;;
    "select_cmd")
      _select_cmd "$label" "$pane_id" "$csv_file"
      exit 0
      ;;
    "info_cmd")
      _info_cmd "$csv_file" "$pane_id" "$csv_file" "$cmd"
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
