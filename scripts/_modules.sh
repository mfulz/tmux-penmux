#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/exported.sh"

_list_modules() {
  local label="$1"
  local loaded_modules="$(_module_get_loaded)"
  local modules="$(find "$_PENMUX_MODULE_DIR" -type f -iname "*\.xml" -printf '%P\n')"
  local unloaded_modules

  while IFS= read -r m; do
    local loaded=""
    while IFS= read -r lm; do
      if [[ "$m" == "$lm" ]]; then
        loaded="yes"
        break
      fi
    done <<< "$loaded_modules"
    if [[ -z "$loaded" ]]; then
      if [[ -z "$unloaded_modules" ]]; then
        unloaded_modules="$m"
      else
        unloaded_modules=$(printf "%s\n%s" "$unloaded_modules" "$m")
      fi
    fi
  done <<< "$modules"

  [[ -z "$label" ]] && label="Select module to load"

  tmux set-option -p @penmux-hidden-module "$(echo "$unloaded_modules" | fzf --preview-window="top,60%" --border-label="$label" --border="sharp" --cycle --preview="$CURRENT_DIR/_modules.sh -a info -m {}")"
}

_list_loaded_modules() {
  local label="$1"
  local loaded_modules="$(_module_get_loaded)"
  
  [[ -z "$label" ]] && label="Select module to unload"

  tmux set-option -p @penmux-hidden-module "$(echo -n "$loaded_modules" | fzf --preview-window="top,60%" --border-label="$label" --border="sharp" --cycle --preview="$CURRENT_DIR/_modules.sh -a info -m {}")"
}

_list_runnable_modules() {
  local label="$1"
  local loaded_modules="$(_module_get_loaded)"
  local runnable_modules
  
  [[ -z "$label" ]] && label="Select module to run"

  while IFS= read -r m; do
    local module_path="$(_module_convert_relative_path "$m")"
    local has_run="$(_module_has_run "$module_path")"

    if [[ "$has_run" == "true" ]]; then
      if [[ -z "$runnable_modules" ]]; then
        runnable_modules="$(printf "%s" "$m")"
      else
        runnable_modules="$(printf "%s\n%s" "$runnable_modules" "$m")"
      fi
    fi
  done <<< "$loaded_modules"

  tmux set-option -p @penmux-hidden-module "$(echo -n "$runnable_modules" | fzf --preview-window="top,60%" --border-label="$label" --border="sharp" --cycle --preview="$CURRENT_DIR/_modules.sh -a info -m {}")"
}

_get_info() {
  local module_file="$(_module_convert_relative_path "$1")"
  local module_name="$(_module_get_name "$module_file")"
  local module_description="$(_module_get_description "$module_file")"
  local module_consumes_plain="$(_module_get_consumes "$module_file")"
  local module_consumes
  local module_provides_plain="$(_module_get_provides "$module_file")"
  local module_provides

  while IFS= read -r e; do
    module_consumes=$(printf "%s\n  %s" "$module_consumes" "$e")
  done <<< "$module_consumes_plain"

  while IFS= read -r e; do
    module_provides=$(printf "%s\n  %s" "$module_provides" "$e")
  done <<< "$module_provides_plain"

  printf "Module: %s\n\nDescription:\n  %s\n\nConsumes:%s\nProvides:%s" "${module_name}" "${module_description}" "${module_consumes}" "${module_provides}"
}

_list_module_options() {
  local module_file="$(_module_convert_relative_path "$1")"
  local label="$2"
  local module_opts="$(_module_get_options "$module_file")"
  local module_name="$(_module_get_name "$module_file")"

  [[ -z "$label" ]] && label="Select option to change for module '$module_name'"

  tmux set-option -p @penmux-hidden-option "$(echo -n "$module_opts" | fzf --preview-window="top,60%" --border-label="$label" --border="sharp" --cycle --preview="$CURRENT_DIR/_modules.sh -a opt_info -m "$module_file" -o {}")"
}

_get_opt_info() {
  local module_file="$1"
  local module_opt="$2"
  local opt_private="$(_module_get_option_private "$module_file" "$module_opt")"
  local opt_exported="$(_module_get_option_exported "$module_file" "$module_opt")"
  local opt_provided="$(_module_get_option_provided "$module_file" "$module_opt")"
  local opt_description="$(_module_get_option_description "$module_file" "$module_opt")"
  local opt_default_value="$(_module_get_option_default_value "$module_file" "$module_opt")"

  printf "Option: %s (Private: %s | Exported: %s | Provided: %s)\n\nDescription:\n  %s\n\nDefault: %s" "${module_opt}" "${opt_private}" "${opt_exported}" "${opt_provided}" "${opt_description}" "${opt_default_value}"
}

_set_option() {
  local module_file="$1"
  local module_opt="$2"
  local module_opt_val="$3"
  local err

  err="$(penmux_module_set_option "$module_file" "$module_opt" "$module_opt_val" 2>&1 1>/dev/null)" || {
    tmux display-message -d 5000 "Error: '$err'"
    exit 0
  }
}

_select_module() {
  local label="$1"
  local module
  tmux display-popup -w 80% -h 80% -E "$CURRENT_DIR/_modules.sh -a list -l \"$label\""
  module="$(tmux show-options -pqv "@penmux-hidden-module")"
  tmux set-option -pu "@penmux-hidden-module" > /dev/null
  echo "${module}"
}

_select_loaded() {
  local label="$1"
  local module
  tmux display-popup -w 80% -h 80% -E "$CURRENT_DIR/_modules.sh -a list_loaded -l \"$label\""
  module="$(tmux show-options -pqv "@penmux-hidden-module")"
  tmux set-option -pu "@penmux-hidden-module" > /dev/null
  echo "${module}"
}

_select_runnable() {
  local label="$1"
  local module
  tmux display-popup -w 80% -h 80% -E "$CURRENT_DIR/_modules.sh -a list_runnable -l \"$label\""
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
  local label

	local OPTIND o
	while getopts "a:m:o:v:l:" o; do
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
		l)
			label="${OPTARG}"
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
			_list_modules "$label"
			;;
		"list_loaded")
			_list_loaded_modules "$label"
			;;
		"list_runnable")
			_list_runnable_modules "$label"
			;;
    "select")
      _select_module "$label"
      ;;
    "select_loaded")
      _select_loaded "$label"
      ;;
    "select_runnable")
      _select_runnable "$label"
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
