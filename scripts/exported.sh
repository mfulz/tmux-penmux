_CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$_CURRENT_DIR/module.sh"

penmux_module_get_exported_options() {
  local pane_id="$1"
  local loaded_modules="$(_module_get_loaded)"
  local opts_arr
  declare -A opts_arr

  while IFS= read -r m; do
    mpath="$(_module_convert_relative_path "$m")"
    mname="$(xmlstarlet sel -t -v "/PenmuxModule/Name" "$mpath")"
    mpopts="$(xmlstarlet sel -t -v "/PenmuxModule/Option[boolean(@Private)=\"true\"][boolean(@Exported)=\"true\"]/Name/text()" "$mpath")"
    mopts="$(xmlstarlet sel -t -v "/PenmuxModule/Option[boolean(@Private)=\"false\"]/Name/text()" "$mpath")"

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
  local module_name
  local option_private
  local option_default
  local tmux_option_name

  # xmlstarlet val sel -t -c "/PenmuxModule/Option[Name=\"$option_name\"]" "${module_path}" >/dev/null || { echo ""; return 1; }

  option_private="$(xmlstarlet sel -t -v "boolean(/PenmuxModule/Option[Name=\"$option_name\"]/@Private)" "$module_path")"
  option_default="$(xmlstarlet sel -t -v "/PenmuxModule/Option[Name=\"$option_name\"]/DefaultValue" "$module_path")"
  module_name="$(xmlstarlet sel -t -v "/PenmuxModule/Name" "$module_path")"

  if [ "$option_private" == "true" ]; then
    tmux_option_name="@penmux-$module_name-$option_name"
  else
    tmux_option_name="@penmux-$option_name"
  fi

  get_tmux_option "$tmux_option_name" "$option_default"
}

penmux_module_set_option() {
  local module_path="${1}"
  local option_name="${2}"
  local value="${3}"
  local pane_id="${4}"
  local module_name
  local option_private
  local option_default
  local tmux_option_name
  local option_type

  # xmlstarlet val sel -t -c "/PenmuxModule/Option[Name=\"$option_name\"]" "${module_path}" >/dev/null || { echo ""; return 1; }

  option_private="$(xmlstarlet sel -t -v "boolean(/PenmuxModule/Option[Name=\"$option_name\"]/@Private)" "$module_path")"
  module_name="$(xmlstarlet sel -t -v "/PenmuxModule/Name" "$module_path")"

  if [ "$option_private" == "true" ]; then
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
          return 1
        fi
        ;;
      "OptionTypeInt")
        if [ "$value" -eq "$value" ] 2>/dev/null; then
          tmux set-option -t "$pane_id" -p "$tmux_option_name" "$value"
        else
          return 1
        fi
        ;;
      "OptionTypeString")
        tmux set-option -t "$pane_id" -p "$tmux_option_name" "$value"
        ;;
      *)
        return 1
        ;;
    esac
  fi

  _module_notify_options "$tmux_option_name" "$pane_id" "$value"
}

penmux_module_notify_consumers() {
  local module_path="${1}"
  local provider_name="${2}"
  local pane_id="${3}"
  local loaded_modules="$(_module_get_loaded)"
  local act_module_path
  local handle_script
  local consumes
  local value

  provider_name="$(xmlstarlet sel -t -v "/PenmuxModule/Provides[Name=\"$provider_name\"]/Name/text()" "$module_path")"

  if [ -z "$provider_name" ]; then
    return 1
  fi

  value="$(get_tmux_option "@penmux-providers-$provider_name" "" "$pane_id")"

  while IFS= read -r m; do
    act_module_path="$(_module_convert_relative_path "$m")"
    consumes="$(xmlstarlet sel -t -v "/PenmuxModule/Consumes[Name=\"$provider_name\"]/Name/text()" "$act_module_path")"
    if [ -n "$consumes" ]; then
      handle_script="$_PENMUX_MODULE_DIR/$(_module_get_handlescript "$act_module_path")"

      [ -z "$handle_script" ] && continue
      "$handle_script" -c "$_CURRENT_DIR" -a notify -m "$act_module_path" -p "$pane_id" -k "$provider_name" -i "$value"
    fi
  done <<< "$loaded_modules"
}

penmux_module_set_provider() {
  local module_path="${1}"
  local provider_name="${2}"
  local value="${3}"
  local tid="${4}"
  local dst="${5}"
  local unset

  provider_name="$(xmlstarlet sel -t -v "/PenmuxModule/Provides[Name=\"$provider_name\"]/Name/text()" "$module_path")"

  if [ -z "$provider_name" ]; then
    return 1
  fi

  if [ -z "$value" ]; then
    unset="-u"
  fi


  case "$dst" in
    "window")
      tmux set-option -t "$tid" -w $unset "@penmux-providers-$provider_name" "$value"
      ;;
    "session")
      tmux set-option -t "$tid" $unset "@penmux-providers-$provider_name" "$value"
      ;;
    *)
      tmux set-option -t "$tid" -p $unset "@penmux-providers-$provider_name" "$value"
      ;;
  esac
}

penmux_module_get_provider() {
  local module_path="${1}"
  local provider_name="${2}"
  local id="${3}"
  local provider_name_final

  provider_name_final="$(xmlstarlet sel -t -v "/PenmuxModule/Provides[Name=\"$provider_name\"]/Name/text()" "$module_path")"
  if [ -z "$provider_name_final" ]; then
    provider_name_final="$(xmlstarlet sel -t -v "/PenmuxModule/Consumes[Name=\"$provider_name\"]/Name/text()" "$module_path")"
    if [ -z "$provider_name_final" ]; then
      return 1
    fi
  fi
  provider_name="$provider_name_final"

  get_tmux_option "@penmux-providers-$provider_name" "" "$id"
}
