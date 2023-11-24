#!/bin/env bash
# @name PenmuxModuleLibrary (scripts/penmux/inc.sh)
# @brief Library that provides penmux functions to the modules
# @description
#   This library must be used in all penmux modules so that
#   they can interact with each other and work together with
#   the penmux API.
#
#   It has the following function blocks:
#     * penmux module functions: Used to read and set options, parse penmux xml files, etc.
#     * general helper functions: These functions provide csv parsing, tmux path expansion, etc.

_INC_CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$_INC_CURRENT_DIR/../include/module.sh"

# @section penmux module functions
# @description The following functions can be used to handle penmux module specific stuff.

# @description This function will return all options that are exported or not Private
# from all loaded modules.
#
# This function will return the options as an array with the plain tmux option names and should
# be used with care.
# Most of the modules should not care about all exported options but for some specific modules
# like Session it is crucial to retrieve all exported options.
#
# @example
#   declare -A exported_options="$(penmux_module_get_exported_options "$pane_id")"
#
# @arg $1 string The ID of the tmux pane that requests the exported options
# @arg $2 boolean If this argument is set only exported options that are not volatile will be returned
#
# @stdout Output either "" or the options as parsable array string
penmux_module_get_exported_options() {
  local pane_id="$1"
  local no_volatile="$2"
  local loaded_modules="$(_module_get_loaded)"
  local opts_arr
  declare -A opts_arr

  while IFS= read -r m; do
    local mpath="$(_module_convert_relative_path "$m")"
    local mname="$(_module_get_name "$mpath")"
    local mpopts="$(xmlstarlet sel -t -v "/PenmuxModule/Option[boolean(@Private)=1][boolean(@Exported)=1]/Name/text()" "$mpath")"
    local mopts="$(xmlstarlet sel -t -v "/PenmuxModule/Option[boolean(@Private)=0][boolean(@Provided)=0]/Name/text()" "$mpath")"
    local popts="$(xmlstarlet sel -t -v "/PenmuxModule/Option[boolean(@Private)=0][boolean(@Provided)=1]/Name/text()" "$mpath")"

    while IFS= read -r o; do
      local oval="$(get_tmux_option_pane "@penmux-$mname-$o" "" "$pane_id")"
      [[ -z "$oval" ]] && continue

      if [[ -n "$no_volatile" ]]; then
        local volatile="$(_module_get_option_volatile "$mpath" "$o")"
        [[ "$volatile" == "true" ]] && continue
      fi
      opts_arr["@penmux-$mname-$o"]="$oval"
    done <<< "$mpopts"

    while IFS= read -r o; do
      local oval="$(get_tmux_option_pane "@penmux-$mname-$o" "" "$pane_id")"
      [[ -z "$oval" ]] && continue

      if [[ -n "$no_volatile" ]]; then
        local volatile="$(_module_get_option_volatile "$mpath" "$o")"
        [[ "$volatile" == "true" ]] && continue
      fi
      opts_arr["@penmux-$mname-$o"]="$oval"
    done <<< "$popts"

    while IFS= read -r o; do
      local oval="$(get_tmux_option_pane "@penmux-$o" "" "$pane_id")"
      [[ -z "$oval" ]] && continue

      if [[ -n "$no_volatile" ]]; then
        local volatile="$(_module_get_option_volatile "$mpath" "$o")"
        [[ "$volatile" == "true" ]] && continue
      fi
      opts_arr["@penmux-$o"]="$oval"
    done <<< "$mopts"
  done <<< "$loaded_modules"

  echo "${opts_arr[@]@K}"
}

# @description This function will return the value for a requested option.
# The requested option must either belong to the calling module or it has
# to be defined as Consumer for the module when it is an external option.
# Only non private options can be retrieved from external modules.
#
# @example
#   option_value="$(penmux_module_get_option "$module_file" "SessionDir" "$pane_id")"
#
# @arg $1 string The absolute path to the module xml definition file
# @arg $2 string The name of the option that is requested (as defined in the xml file)
# @arg $3 string The ID of the tmux pane that requests the option
#
# @stdout Output either "" (if no default value found), the default value or the actual value that was set by the user
penmux_module_get_option() {
  local module_path="${1}"
  local option_name="${2}"
  local pane_id="${3}"
  local module_name="$(_module_get_name "$module_path")"
  local option_name_xml="$(_module_get_option_name "$module_path" "$option_name")"
  local option_private
  local option_provided
  local option_default
  local tmux_option_name

  if [[ -z "$option_name_xml" ]]; then
    option_name_xml="$(_module_get_consumer_name "$module_path" "$option_name")"
    module_name="$(_module_get_consumer_from "$module_path" "$option_name")"
    tmux_option_name="@penmux-$module_name-$option_name"
  else
    option_private="$(_module_get_option_private "$module_path" "$option_name")"
    option_provided="$(_module_get_option_provided "$module_path" "$option_name")"
    option_default="$(_module_get_option_default_value "$module_path" "$option_name")"

    if [[ "$option_private" == "true" || "$option_provided" == "true" ]]; then
      tmux_option_name="@penmux-$module_name-$option_name"
    else
      tmux_option_name="@penmux-$option_name"
    fi
  fi

  [[ -z "$option_name_xml" ]] && return

  get_tmux_option_pane "$tmux_option_name" "$option_default" "$pane_id"
}

# @description This function will set a value for a requested option.
# The requested option must  belong to the calling module.
#
# @example
#   penmux_module_set_option "$module_file" "HttpPort" "80" "$pane_id"
#
# @arg $1 string The absolute path to the module xml definition file
# @arg $2 string The name of the option that is should be set (as defined in the xml file)
# @arg $3 string The new value that should be set
# @arg $4 string The ID of the tmux pane which option should be set
#
# @stderr Output an error that describes what went wrong on error
#
# @exitcode 0 If successful
# @exitcode 1 If an error happend
penmux_module_set_option() {
  local module_path="${1}"
  local option_name="${2}"
  local value="${3}"
  local pane_id="${4}"
  local module_name
  local opt_private="$(_module_get_option_private "$module_path" "$option_name")"
  local opt_exported="$(_module_get_option_exported "$module_path" "$option_name")"
  local opt_volatile="$(_module_get_option_volatile "$module_path" "$option_name")"
  local opt_provided="$(_module_get_option_provided "$module_path" "$option_name")"
  local option_default
  local tmux_option_name
  local option_type

  # xmlstarlet val sel -t -c "/PenmuxModule/Option[Name=\"$option_name\"]" "${module_path}" >/dev/null || { echo ""; return 1; }

  module_name="$(xmlstarlet sel -t -v "/PenmuxModule/Name" "$module_path")"

  if [[ "$opt_private" == "true" || "$opt_provided" == "true" ]]; then
    tmux_option_name="@penmux-$module_name-$option_name"
  else
    tmux_option_name="@penmux-$option_name"
  fi

  if [ -z "$pane_id" ]; then
    pane_id="$(tmux display-message -p '#D')"
  fi

  if [ -z "$value" ]; then
    tmux set-option -t "$pane_id" -p -u "$tmux_option_name"
  else
    option_type="$(_module_get_option_type "$module_path" "$option_name")"
    case "$option_type" in
      "OptionTypeBool")
        if [ "$value" == "true" ] || [ "$value" == "false" ]; then
          tmux set-option -t "$pane_id" -p "$tmux_option_name" "$value"
        else
          echo >&2 "Wrong option value '$value' for type 'OptionTypeBool'"
          return 1
        fi
        ;;
      "OptionTypeInt")
        if [ "$value" -eq "$value" ] 2>/dev/null; then
          tmux set-option -t "$pane_id" -p "$tmux_option_name" "$value"
        else
          echo >&2 "Wrong option value '$value' for type 'OptionTypeBool'"
          return 1
        fi
        ;;
      "OptionTypeString")
        tmux set-option -t "$pane_id" -p "$tmux_option_name" "$value"
        ;;
      *)
        echo >&2 "Unknown option type '$option_type'"
        return 1
        ;;
    esac
  fi

  [[ "$opt_private" == "true" && "$opt_exported" == "false" ]] && return
  _module_notify_options "$tmux_option_name" "$pane_id" "$value" "$opt_volatile"
}

# @description This function will notify all loaded modules that
# has a consumer for this option and not flagged it NoNotify about
# the change.
#
# The requested option must  belong to the calling module and flagged 
# Provided. Further it must not be flagged Private.
#
# @example
#   penmux_module_notify_consumers "$module_file" "SessionDir" "$pane_id"
#
# @arg $1 string The absolute path to the module xml definition file
# @arg $2 string The name of the option that was set
# @arg $3 string The ID of the tmux pane which set the option
#
# @exitcode 0 If successful
# @exitcode 1 If option is private
# @exitcode 2 If option is not provided
penmux_module_notify_consumers() {
  local module_path="${1}"
  local option_name="${2}"
  local pane_id="${3}"
  local loaded_modules="$(_module_get_loaded)"
  local option_private="$(_module_get_option_private "$module_path" "$option_name")"
  local option_provided="$(_module_get_option_provided "$module_path" "$option_name")"
  local act_module_path
  local consumes
  local value

  [[ "$option_private" == "true" ]] && return 1
  [[ "$option_provided" == "true" ]] || return 2

  value="$(get_tmux_option "$module_path" "$option_name" "$pane_id")"

  while IFS= read -r m; do
    act_module_path="$(_module_convert_relative_path "$m")"
    consumes="$(xmlstarlet sel -t -v "/PenmuxModule/Consumes[Name=\"$option_name\"][boolean(@NoNotify)=0]/Name/text()" "$act_module_path")"
    if [ -n "$consumes" ]; then
      "$_INC_CURRENT_DIR/../bin/internal/handler.sh" "$act_module_path" -a consumes -p "$pane_id" -n "$option_name" -v "$value"
    fi
  done <<< "$loaded_modules"
}

# @description This function will expand a given string by replacing
# penmux format specifiers
#
# It will use penmux_module_get_option internally so all the rules
# for retrieving an option will match here too.
#
# @example
#   final_command="$(penmux_module_expand_options_string "$module_file" "###SessionDir###mymodule" "$pane_id")"
#
# @arg $1 string The absolute path to the module xml definition file
# @arg $2 string The input string that should be expanded
# @arg $3 string The ID of the tmux pane where the options should be read from
#
# @stdout Outputs the expanded input string
penmux_module_expand_options_string() {
  local module_path="${1}"
  local input="${2}"
  local pane_id="${3}"
  local replacements="$(echo "$input" | grep -E '###([^###]*)###' -o | sed 's/###//g')"

  while IFS= read -r r; do
    local v="$(penmux_module_get_option "$module_path" "$r" "$pane_id")"
    input="${input//"###${r}###"/$v}"
  done <<< "$replacements"
  # quickfix for no session dir
  # TODO: Valid handling
  # input="${input/\/\//\/}"

  echo "$input"
}

# @description This function tells if a module is loaded
#
# @example
#   loaded="$(penmux_module_is_loaded "auxilliary/Session.xml")"
#   if [[ "$loaded" == "yes" ]]; then
#     do anything when module is loaded
#   else
#     do anything when module is not loaded
#   fi
#
# @arg $1 string The path to the module xml relative to the module search path
#
# @stdout Outputs yes if module is loaded or "" when it is not loaded
penmux_module_is_loaded() {
  local module="$1"

  _module_get_loaded "$module"
}

# @section general helper functions
# @description The following functions can be used to for general recurring tasks.

# @description This function parse a given csv content and print parsable lines
# that can be assigned to arrays.
#
# The lines will contain an array with the heading columns as key and the
# matching column content as value.
#
# @example
#   csv_content="$(cat input.csv)"
#   csv_parsed="$(penmux_csv_to_arrays "$csv_content")"
#   while IFS= read -r e; do
#     declare -A earr="($(echo "$e"))"
#   done <<< "$csv_parsed"
#
# @arg $1 string The content from the csv file
# @arg $2 char A separator. This is optional and ',' will be used when not given
#
# @stdout Output either "" or the parsed csv data
penmux_csv_to_arrays() {
  local csv_content="$1"
  local csv_sep="$2"
  local csv_header
  local csv_col_nums

  declare -A csv_header

  [[ -z "$csv_sep" ]] && csv_sep=","

  while IFS= read -r l; do
    if [[ -z "$csv_col_nums" ]]; then
      csv_col_nums="$(echo "$l" | awk -F"$csv_sep" '{print NF}')"
      for (( i=0 ; i<csv_col_nums ; i++ )); do
        y=$((i+1))
        csv_header[$i]="$(echo "$l" | awk -F"$csv_sep" '{print $'$y'}')"
      done
      echo "${csv_header[@]@K}"
    else
      local csv_line
      declare -A csv_line
      for (( i=0 ; i<csv_col_nums ; i++ )); do
        y=$((i+1))
        if [[ "$y" -eq "$csv_col_nums" ]]; then
          csv_line[${csv_header[$i]}]="$(echo "$l" | cut -d"$csv_sep" -f$y-)"
        else
          csv_line[${csv_header[$i]}]="$(echo "$l" | awk -F"$csv_sep" '{print $'$y'}')"
        fi
      done
      echo "${csv_line[@]@K}"
    fi
  done <<< "$csv_content"
}

# @description This function parse a given array content and
# print the corresponding csv content.
#
# @example
#   csv_parsed="$(penmux_csv_to_arrays "$csv_content")"
#   csv_content="$(penmux_arrays_to_csv "$csv_parsed")"
#   echo "$csv_content" > output.csv
#
# @arg $1 string The content of the csv like array
# @arg $2 char A separator. This is optional and ',' will be used when not given
#
# @stdout Output either "" or the parsed csv data
penmux_arrays_to_csv() {
  local csv_content="$1"
  local csv_sep="$2"
  local csv_header
  local csv_col_nums
  local csv_header

  [[ -z "$csv_sep" ]] && csv_sep=","

  while IFS= read -r l; do
    if [[ -z "$csv_col_nums" ]]; then
      declare -A csv_header="($(echo "$l"))"
      csv_col_nums="${#csv_header[@]}"

      for (( i=0 ; i<csv_col_nums ; i++ )); do
        if [[ "$i" -eq 0 ]]; then
          printf "%s" "${csv_header[$i]}"
        else
          printf "%s%s" "$csv_sep" "${csv_header[$i]}"
        fi
      done
      printf "\n"
    else
      local csv_line
      declare -A csv_line="($(echo "$l"))"

      for (( i=0 ; i<csv_col_nums ; i++ )); do
        if [[ "$i" -eq 0 ]]; then
          printf "%s" "${csv_line[${csv_header[$i]}]}"
        else
          printf "%s%s" "$csv_sep" "${csv_line[${csv_header[$i]}]}"
        fi
      done
      printf "\n"
    fi
  done <<< "$csv_content"
}

# @description This function will expand a given string by replacing
# tmux format specifiers
#
# @example
#   final_path="$(penmux_expand_tmux_format_path "$pane_id" "%H-#S.log")"
#
# @arg $1 string The ID of the tmux pane where the options should be read from
# @arg $2 string The input string that should be expanded
# @arg $3 boolean If the path should be kept relative
#
# @stdout Outputs the expanded input string
penmux_expand_tmux_format_path() {
  local pane_id="$1"
	local tmux_format_path="${2}"
  local no_absolute="${3}"
	local full_path=$(tmux display-message -t "$pane_id" -p "${tmux_format_path}")
  full_path="$(echo "$full_path" | sed "s,\$HOME,$HOME,g; s,\$HOSTNAME,$(hostname),g; s,\~,$HOME,g")"

  if [[ "$full_path" != /* && -z "$no_absolute" ]]; then
    full_path="$(tmux display-message -t "$pane_id" -p '#{pane_current_path}')/${full_path}"
  fi

  echo "$full_path"
}
