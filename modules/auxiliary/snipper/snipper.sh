#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PENMUX_SCRIPTS=""
_MODULE_PATH=""

source "$CURRENT_DIR/shared.sh"

_list_csv() {
  local label="$1"
  local pane_id="$2"
  local snippet_search_path="$(penmux_module_get_option "$_MODULE_PATH" "SnippetSearchPath" "$pane_id")"
  snippet_search_path="$(penmux_expand_tmux_format_path "$pane_id" "$snippet_search_path")"

  [[ -z "$label" ]] && label="Select snippet file"

  tmux set-option -p @penmux-snipper-hidden-csv "$(find "$snippet_search_path" -type f -iname '*.csv' -printf '%P\n' | fzf --preview-window="top,60%" --border-label="$label" --border="sharp" --cycle --preview="$CURRENT_DIR/snipper.sh -a info_csv -c "$_PENMUX_SCRIPTS" -m "$_MODULE_PATH" -p "$pane_id" -f {}")"
}

_info_csv() {
  local csv="$1"
  local pane_id="$2"
  local snippet_search_path="$(penmux_module_get_option "$_MODULE_PATH" "SnippetSearchPath" "$pane_id")"
  local csv_desc="$snippet_search_path/$(echo "$csv" | rev | cut -f 2- -d '.' | rev).desc"
  csv_desc="$(penmux_expand_tmux_format_path "$pane_id" "$csv_desc")"

  cat "$csv_desc"
}

_list_snippet() {
  local label="$1"
  local pane_id="$2"
  local csv_file="$3"
  local snippet_search_path="$(penmux_module_get_option "$_MODULE_PATH" "SnippetSearchPath" "$pane_id")"
  csv_file="$snippet_search_path/$csv_file"
  csv_file="$(penmux_expand_tmux_format_path "$pane_id" "$csv_file")"
  local csv_content="$(cat "$csv_file")"
  local csv_arrays="$(penmux_csv_to_arrays "$csv_content")"
  local csv_names
  local csv_first="1"
  local snippet

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

  [[ -z "$label" ]] && label="Select snippet"

  snippet="$(echo "$csv_names" | fzf --preview-window="top,60%" --border-label="$label" --border="sharp" --cycle --preview="$CURRENT_DIR/snipper.sh -a info_snippet -c "$_PENMUX_SCRIPTS" -m "$_MODULE_PATH" -p "$pane_id" -f "$csv_file" -s {}")"

  [[ -z "$snippet" ]] && return

  while IFS= read -r l; do
    local csv_entry
    local csv_snippet
    declare -A csv_entry="($(echo "$l"))"

    if [[ "${csv_entry["name"]}" == "$snippet" ]]; then
      csv_snippet="$(penmux_module_expand_options_string "$_MODULE_PATH" "${csv_entry["snippet"]}" "$pane_id")"
      csv_snippet="$(penmux_expand_tmux_format_path "$pane_id" "$csv_snippet" "1")"

      tmux set-option -p @penmux-snipper-hidden-snippet "$csv_snippet"
      tmux set-option -p @penmux-snipper-hidden-snippet-variables "${csv_entry["variables"]}"
      return
    fi
  done <<< "$csv_arrays" 
}

_info_snippet() {
  local label="$1"
  local pane_id="$2"
  local csv_file="$3"
  local snippet="$4"
  local csv_content="$(cat "$csv_file")"
  local csv_arrays="$(penmux_csv_to_arrays "$csv_content")"

  while IFS= read -r l; do
    local csv_entry
    local csv_snippet
    declare -A csv_entry="($(echo "$l"))"

    if [[ "${csv_entry["name"]}" == "$snippet" ]]; then
      csv_snippet="$(penmux_module_expand_options_string "$_MODULE_PATH" "${csv_entry["snippet"]}" "$pane_id")"
      csv_snippet="$(penmux_expand_tmux_format_path "$pane_id" "$csv_snippet" "1")"

      printf "Description: %s\n\nSnippet: %s\n" "${csv_entry["description"]}" "$csv_snippet"
      if [[ -n "${csv_entry["variables"]}" ]]; then
        printf "\nVariables: \n"
        local variables="$(_variables_to_arrays "${csv_entry["variables"]}")"

        while IFS= read -r v; do
          local variable
          declare -A variable="($(echo "$v"))"

          printf "  Name: %s\n  Value: %s\n  Description: %s\n\n" "${variable["name"]}" "${variable["value"]}" "${variable["desc"]}"
        done <<< "$variables"
      fi

      return
    fi
  done <<< "$csv_arrays"
}

_select_csv() {
  local label="$1"
  local pane_id="$2"
  local csv

  tmux display-popup -w 80% -h 80% -E "$CURRENT_DIR/snipper.sh -a list_csv -c \"$_PENMUX_SCRIPTS\" -l \"$label\" -m \"$_MODULE_PATH\" -p \"$pane_id\""
  csv="$(tmux show-options -pqv "@penmux-snipper-hidden-csv")"
  tmux set-option -pu "@penmux-snipper-hidden-csv" > /dev/null
  echo "${csv}"
}

_select_snippet() {
  local label="$1"
  local pane_id="$2"
  local csv="$3"
  local snippet
  local variables

  tmux display-popup -w 80% -h 80% -E "$CURRENT_DIR/snipper.sh -a list_snippet -c \"$_PENMUX_SCRIPTS\" -l \"$label\" -m \"$_MODULE_PATH\" -p \"$pane_id\" -f \"$csv\""
  snippet="$(tmux show-options -pqv "@penmux-snipper-hidden-snippet")"
  variables="$(tmux show-options -pqv "@penmux-snipper-hidden-snippet-variables")"
  variables="$(_variables_to_arrays "$variables")"
  tmux set-option -pu "@penmux-snipper-hidden-snippet" > /dev/null
  tmux set-option -pu "@penmux-snipper-hidden-snippet-variables" > /dev/null

  if [[ -n "$variables" ]]; then
    while IFS= read -r v; do
      local val
      local variable
      declare -A variable="($(echo "$v"))"

      val="$(tmux command-prompt -p "Set value for '${variable["name"]}': " -I "${variable["value"]}" "display-message -p '%%'")"
      if [[ -z "$val" ]]; then
        echo ""
        return
      fi
      snippet="${snippet//"§§§${variable["name"]}§§§"/$val}"
    done <<< "$variables"
  fi
  echo "${snippet}"
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
    "list_snippet")
      _list_snippet "$label" "$pane_id" "$csv_file"
      exit 0
      ;;
    "select_snippet")
      _select_snippet "$label" "$pane_id" "$csv_file"
      exit 0
      ;;
    "info_snippet")
      _info_snippet "$csv_file" "$pane_id" "$csv_file" "$cmd"
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
