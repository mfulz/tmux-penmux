#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/exported.sh"

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

_list_module_options() {
  local module_file="$(penmux_module_convert_relative_path "$1")"
  local module_opts="$(penmux_module_get_options "$module_file")"
  tmux set-option -p @penmux-hidden-option "$(echo -n "$module_opts" | fzf --cycle --preview="$CURRENT_DIR/_modules.sh -a opt_info -m "$module_file" -o {}")"
}

_get_opt_info() {
  local module_file="$1"
  local module_opt="$2"
  local opt_private="$(penmux_module_get_option_private "$module_file" "$module_opt")"
  local opt_exported="$(penmux_module_get_option_exported "$module_file" "$module_opt")"
  local opt_description="$(penmux_module_get_option_description "$module_file" "$module_opt")"
  local opt_default_value="$(penmux_module_get_option_default_value "$module_file" "$module_opt")"

  printf "Option: %s (Private: %s | Exported: %s)\n\nDescription:\n  %s\n\nDefault:%s" "${module_opt}" "${opt_private}" "${opt_exported}" "${opt_description}" "${opt_default_value}"
}

_set_option() {
  local module_file="$1"
  local module_opt="$2"
  local module_opt_val="$3"

  penmux_module_set_option "$module_file" "$module_opt" "$module_opt_val"
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

_select_option() {
  local module_file="$1"
  local option
  tmux display-popup -w 80% -h 80% -E "$CURRENT_DIR/_modules.sh -a list_options -m \"$module_file\""
  option="$(tmux show-options -pqv "@penmux-hidden-option")"
  tmux set-option -pu "@penmux-hidden-option" > /dev/null
  echo "${option}"
}

main() {
	local action
  local module_file
  local module_opt
  local module_opt_val

	local OPTIND o
	while getopts "a:m:o:v:" o; do
		case "${o}" in
		a)
			action="${OPTARG}"
			;;
		m)
			module_file="${OPTARG}"
			;;
		o)
			module_opt="${OPTARG}"
			;;
		v)
			module_opt_val="${OPTARG}"
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
    "list_options")
			_list_module_options "${module_file}"
			;;
    "opt_info")
			_get_opt_info "${module_file}" "${module_opt}"
			;;
    "select_option")
			_select_option "${module_file}"
			;;
    "set_option")
			_set_option "${module_file}" "${module_opt}" "$module_opt_val"
			;;
		*)
			echo >&2 "Invalid action '${action}'"
			exit 1
			;;
		esac
	fi
}
main "$@"
