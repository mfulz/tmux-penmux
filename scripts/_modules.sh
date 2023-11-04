#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/helpers.sh"

_list_modules() {
  tmux set-option -p @penmux-hidden-module "$(find "$_PENMUX_MODULE_DIR" -type f -iname "*\.xml" -printf '%P\n' | fzf --cycle --preview="$CURRENT_DIR/_modules.sh -a info -m {}")"
}

_list_loaded_modules() {
  local loaded_modules="$(penmux_module_get_loaded)"
  tmux set-option -p @penmux-hidden-module "$(echo -n "$loaded_modules" | fzf --cycle --preview="$CURRENT_DIR/_modules.sh -a info -m {}")"
}

_get_info() {
  local module_file="$(penmux_module_convert_relative_path "$1")"
  local module_name="$(penmux_module_get_name "$module_file")"
  local module_description="$(penmux_module_get_description "$module_file")"
  local module_uses_plain="$(penmux_module_get_uses "$module_file")"
  local module_uses
  local module_depends_plain="$(penmux_module_get_depends "$module_file")"
  local module_depends

  while IFS= read -r e; do
    module_uses=$(printf "%s\n  %s" "$module_uses" "$e")
  done <<< "$module_uses_plain"

  while IFS= read -r e; do
    module_depends=$(printf "%s\n  %s" "$module_depends" "$e")
  done <<< "$module_depends_plain"

  printf "Module: %s\n\nDescription:\n  %s\n\nDepends:%s\n\nUses:%s" "${module_name}" "${module_description}" "${module_depends}" "${module_uses}"
}

_select_module() {
  local module
  tmux display-popup -w 80% -h 80% -E "$CURRENT_DIR/_modules.sh -a list"
  module="$(tmux show-options -pqv "@penmux-hidden-module")"
  tmux set-option -pu "@penmux-hidden-module" > /dev/null
  echo "${module}"
}

_select_loaded() {
  local module
  tmux display-popup -w 80% -h 80% -E "$CURRENT_DIR/_modules.sh -a list_loaded"
  module="$(tmux show-options -pqv "@penmux-hidden-module")"
  tmux set-option -pu "@penmux-hidden-module" > /dev/null
  echo "${module}"
}

main() {
	local action
  local module_file

	local OPTIND o
	while getopts "a:m:" o; do
		case "${o}" in
		a)
			action="${OPTARG}"
			;;
		m)
			module_file="${OPTARG}"
			;;
		*)
			echo >&2 "Invalid parameter"
			exit 1
			;;
		esac
	done

	if supported_tmux_version_ok; then
		case "${action}" in
		"list")
			_list_modules
			;;
		"list_loaded")
			_list_loaded_modules
			;;
    "select")
      _select_module
      ;;
    "select_loaded")
      _select_loaded
      ;;
    "info")
			_get_info "${module_file}"
			;;
		*)
			echo >&2 "Invalid action '${action}'"
			exit 1
			;;
		esac
	fi
}
main "$@"
