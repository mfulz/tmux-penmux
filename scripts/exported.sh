_CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$_CURRENT_DIR/module.sh"

# penmux module functions
penmux_module_get_exported_options() {
  local pane_id="$1"
  local loaded_modules="$(_module_get_loaded)"
  local opts_arr
  declare -A opts_arr

  while IFS= read -r m; do
    mpath="$(_module_convert_relative_path "$m")"
    mname="$(xmlstarlet sel -t -v "/PenmuxModule/Name" "$mpath")"
    mpopts="$(xmlstarlet sel -t -v "/PenmuxModule/Option[boolean(@Private)=1][boolean(@Exported)=1]/Name/text()" "$mpath")"
    mopts="$(xmlstarlet sel -t -v "/PenmuxModule/Option[boolean(@Private)=0]/Name/text()" "$mpath")"

    while IFS= read -r o; do
      local oval="$(get_tmux_option_pane "@penmux-$mname-$o" "" "$pane_id")"
      [[ -z "$oval" ]] && continue
      opts_arr["@penmux-$mname-$o"]="$oval"
    done <<< "$mpopts"

    while IFS= read -r o; do
      local oval="$(get_tmux_option_pane "@penmux-$o" "" "$pane_id")"
      [[ -z "$oval" ]] && continue
      opts_arr["@penmux-$o"]="$oval"
    done <<< "$mopts"
  done <<< "$loaded_modules"

  echo "${opts_arr[@]@K}"
}

penmux_module_get_option() {
  local module_path="${1}"
  local option_name="${2}"
  local pane_id="${3}"
  local option_name_xml
  local module_name
  local option_private
  local option_default
  local tmux_option_name


  # xmlstarlet val sel -t -c "/PenmuxModule/Option[Name=\"$option_name\"]" "${module_path}" >/dev/null || { echo ""; return 1; }
  option_name_xml="$(xmlstarlet sel -t -v "/PenmuxModule/Option[Name=\"$option_name\"]/Name/text()" "$module_path")"
  if [[ -n "$option_name_xml" ]]; then
    option_private="$(xmlstarlet sel -t -v "boolean(/PenmuxModule/Option[Name=\"$option_name\"]/@Private)" "$module_path")"
    option_default="$(xmlstarlet sel -t -v "/PenmuxModule/Option[Name=\"$option_name\"]/DefaultValue" "$module_path")"
    module_name="$(xmlstarlet sel -t -v "/PenmuxModule/Name" "$module_path")"
  else
    option_name_xml="$(xmlstarlet sel -t -v "/PenmuxModule/Consumes[Name=\"$option_name\"]/Name/text()" "$module_path")"
  fi

  [[ -z "$option_name_xml" ]] && return

  if [ "$option_private" == "true" ]; then
    tmux_option_name="@penmux-$module_name-$option_name"
  else
    tmux_option_name="@penmux-$option_name"
  fi

  get_tmux_option_pane "$tmux_option_name" "$option_default" "$pane_id"
}

penmux_module_set_option() {
  local module_path="${1}"
  local option_name="${2}"
  local value="${3}"
  local pane_id="${4}"
  local module_name
  local opt_private="$(_module_get_option_private "$module_path" "$option_name")"
  local opt_exported="$(_module_get_option_exported "$module_path" "$option_name")"
  local option_default
  local tmux_option_name
  local option_type

  # xmlstarlet val sel -t -c "/PenmuxModule/Option[Name=\"$option_name\"]" "${module_path}" >/dev/null || { echo ""; return 1; }

  module_name="$(xmlstarlet sel -t -v "/PenmuxModule/Name" "$module_path")"

  if [[ "$opt_private" == "true" ]]; then
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
  _module_notify_options "$tmux_option_name" "$pane_id" "$value"
}

penmux_module_notify_consumers() {
  local module_path="${1}"
  local option_name="${2}"
  local pane_id="${3}"
  local loaded_modules="$(_module_get_loaded)"
  local option_private="$(_module_get_option_private "$module_path" "$option_name")"
  local option_provided="$(_module_get_option_provided "$module_path" "$option_name")"
  local act_module_path
  local handle_script
  local consumes
  local value

  [[ "$option_private" == "true" ]] && return
  [[ "$option_provided" == "true" ]] || return

  value="$(get_tmux_option "$module_path" "$option_name" "$pane_id")"

  while IFS= read -r m; do
    act_module_path="$(_module_convert_relative_path "$m")"
    consumes="$(xmlstarlet sel -t -v "/PenmuxModule/Consumes[Name=\"$option_name\"][boolean(@NoNotify)=0]/Name/text()" "$act_module_path")"
    if [ -n "$consumes" ]; then
      handle_script="$_PENMUX_MODULE_DIR/$(_module_get_handlescript "$act_module_path")"

      [ -z "$handle_script" ] && continue
      "$handle_script" -c "$_CURRENT_DIR" -a consumes -m "$act_module_path" -p "$pane_id" -k "$option_name" -i "$value"
    fi
  done <<< "$loaded_modules"
}

penmux_module_expand_options_string() {
  local module_path="${1}"
  local input="${2}"
  local pane_id="${3}"
  local replacements="$(echo "$input" | grep -E '###([^###]*)###' -o | sed 's/###//g')"

  while IFS= read -r r; do
    local v="$(penmux_module_get_option "$module_path" "$r" "$pane_id")"
    input="${input/"###${r}###"/$v}"
  done <<< "$replacements"
  # quickfix for no session dir
  # TODO: Valid handling
  # input="${input/\/\//\/}"

  echo "$input"
}

penmux_module_is_loaded() {
  local module="$1"

  _module_get_loaded "$module"
}

# generel helper functions
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
        csv_line[${csv_header[$i]}]="$(echo "$l" | awk -F"$csv_sep" '{print $'$y'}')"
      done
      echo "${csv_line[@]@K}"
    fi
  done <<< "$csv_content"
}

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

penmux_expand_tmux_format_path() {
  local pane_id="$1"
	local tmux_format_path="${2}"
	local full_path=$(tmux display-message -t "$pane_id" -p "${tmux_format_path}")
  echo "$full_path" | sed "s,\$HOME,$HOME,g; s,\$HOSTNAME,$(hostname),g; s,\~,$HOME,g"
}
