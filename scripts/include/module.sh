_MODULE_CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$_MODULE_CURRENT_DIR/helpers.sh"

#
# module stuff
_module_validate() {
  local module_path="${1}"

  err=$(xmlstarlet val --xsd "${_PENMUX_MODULE_SCHEMA}" "${module_path}" 2>&1 1>/dev/null) || { echo >&2 "${err}"; return 1; }
}

_module_get_name() {
  local module_path="${1}"

  xmlstarlet sel -t -v '/PenmuxModule/Name' -n "${module_path}"
}

_module_get_description() {
  local module_path="${1}"

  xmlstarlet sel -t -v '/PenmuxModule/Description' -n "${module_path}"
}

_module_get_provides() {
  local module_path="${1}"

  xmlstarlet sel -t -v '/PenmuxModule/Option[boolean(@Provided)=1]' -n "${module_path}"
}

_module_get_consumes() {
  local module_path="${1}"

  xmlstarlet sel -t -v '/PenmuxModule/Consumes' -n "${module_path}"
}

_module_get_cmdprio() {
  local module_path="${1}"

  xmlstarlet sel -t -v '/PenmuxModule/CmdPrio' -n "${module_path}"
}

_module_get_options() {
  local module_path="$1"

  xmlstarlet sel -t -v "/PenmuxModule/Option[boolean(@Provided)=0]/Name/text()" "$module_path"
}

_module_get_option_name() {
  local module_path="$1"
  local option_name="$2"

  xmlstarlet sel -t -v "/PenmuxModule/Option[Name=\"$option_name\"]/Name/text()" "$module_path"
}

_module_get_consumer_name() {
  local module_path="$1"
  local consumer_name="$2"

  xmlstarlet sel -t -v "/PenmuxModule/Consumes[Name=\"$consumer_name\"]/Name/text()" "$module_path"
}

_module_get_consumer_from() {
  local module_path="$1"
  local consumer_name="$2"

  xmlstarlet sel -t -v "/PenmuxModule/Consumes[Name=\"$consumer_name\"]/From/text()" "$module_path"
}

_module_get_option_private() {
  local module_path="$1"
  local option_name="$2"

  xmlstarlet sel -t -v "boolean(/PenmuxModule/Option[Name=\"$option_name\"]/@Private)" "$module_path"
}

_module_get_option_exported() {
  local module_path="$1"
  local option_name="$2"

  xmlstarlet sel -t -v "boolean(/PenmuxModule/Option[Name=\"$option_name\"]/@Exported)" "$module_path"
}

_module_get_option_volatile() {
  local module_path="$1"
  local option_name="$2"

  xmlstarlet sel -t -v "boolean(/PenmuxModule/Option[Name=\"$option_name\"]/@Volatile)" "$module_path"
}

_module_get_option_provided() {
  local module_path="$1"
  local option_name="$2"

  xmlstarlet sel -t -v "boolean(/PenmuxModule/Option[Name=\"$option_name\"]/@Provided)" "$module_path"
}

_module_get_option_type() {
  local module_path="$1"
  local option_name="$2"

  xmlstarlet sel -t -v "/PenmuxModule/Option[Name=\"$option_name\"]/@xsi:type" "$module_path"
}

_module_get_option_description() {
  local module_path="$1"
  local option_name="$2"

  xmlstarlet sel -t -v "/PenmuxModule/Option[Name=\"$option_name\"]/Description/text()" "$module_path"
}

_module_get_options_file() {
  local module_path="$1"
  local module_name="$(_module_get_name "$module_path")"
  local custom_module_options_dir_value="$(get_tmux_option "$custom_module_options_dir_option" "$default_custom_module_options_dir")"
  local options_file

  if [[ -e "$custom_module_options_dir_value/$module_name.xml" ]]; then
    options_file="$custom_module_options_dir_value/$module_name.xml"
  elif [[ -e "$_PENMUX_MODULE_OPTIONS_DIR/$module_name.xml" ]]; then
    options_file="$_PENMUX_MODULE_OPTIONS_DIR/$module_name.xml"
  else
    options_file=""
  fi

  echo "$options_file"
}

_module_has_option_global() {
  local module_file="$1"
  local option_name="$2"
  local option_name_xml="$(_module_get_option_name "$module_file" "$option_name")"
  local opt_private
  local opt_provided

  [[ -z "$option_name_xml" ]] && return 1

  opt_private="$(_module_get_option_private "$module_file" "$option_name")"
  opt_provided="$(_module_get_option_provided "$module_file" "$option_name")"
  [[ "$opt_private" == "true" || "$opt_provided" == "true" ]] && return 1

  return 0
}

_module_get_option_default_value() {
  local module_path="$1"
  local option_name="$2"
  local module_name="$(_module_get_name "$module_path")"
  local custom_module_options_dir_value="$(get_tmux_option "$custom_module_options_dir_option" "$default_custom_module_options_dir")"
  local options_file="$(_module_get_options_file "$module_path")"
  local option_default

  if [[ -n "$options_file" ]]; then
    option_default="$(xmlstarlet sel -t -v "/PenmuxModuleOptions/Option[Name=\"$option_name\"]/DefaultValue" "$options_file")"
  fi

  echo "$option_default"
}

_module_has_run() {
  local module_path="$1"

  xmlstarlet sel -t -v "boolean(/PenmuxModule/HasRun)" "$module_path"
}

_module_convert_relative_path() {
  local relative_path="$1"
  echo "$_PENMUX_MODULE_DIR/$relative_path"
}

_module_get_loaded() {
  local loaded_modules_plain="$(get_tmux_option "@penmux-loaded-modules" "")"
  local loaded_modules

  IFS=#
  for m in $loaded_modules_plain; do
    [ -z "$m" ] && continue
    if [ -z "$loaded_modules" ]; then
      loaded_modules="$m"
    else
      loaded_modules=$(printf "%s\n%s" "$loaded_modules" "$m")
    fi
  done

  echo "$loaded_modules"
}

_module_is_loaded() {
  local module="$1"
  local loaded_modules="$(_module_get_loaded)"

  while IFS= read -r m; do
    if [[ "$module" == "$m" ]]; then
      echo "yes"
      return
    fi
  done <<< "$loaded_modules"
}

_module_notify_options() {
  local opt_name="${1}"
  local pane_id="${2}"
  local opt_value="${3}"
  local opt_volatile="${4}"
  local loaded_modules="$(_module_get_loaded)"
  local opts_notify

  while IFS= read -r m; do
    act_module_path="$(_module_convert_relative_path "$m")"
    opts_notify="$(xmlstarlet sel -t -v "boolean(/PenmuxModule/NotifyOptions)" "$act_module_path")"
    if [[ "$opts_notify" == "true" ]]; then
      if [ -z "$opt_value" ]; then
        "$_MODULE_CURRENT_DIR/../bin/internal/handler.sh" "$act_module_path" -a optionsnotify -p "$pane_id" -n "$opt_name" -s "$opt_volatile"
      else
        "$_MODULE_CURRENT_DIR/../bin/internal/handler.sh" "$act_module_path" -a optionsnotify -p "$pane_id" -n "$opt_name" -s "$opt_volatile" -v "$opt_value"
      fi
    fi
  done <<< "$loaded_modules"
}

# hooks
_module_check_hook() {
  local module_path="$1"
  local hook="$2"

  xmlstarlet sel -t -v "boolean(/PenmuxModule/Hooks/$hook)" "$module_path"
}

_module_run_hook() {
  local hook="$1"
  local hook_option="$2"
  local loaded_modules="$(_module_get_loaded)"

  while IFS= read -r m; do
    local mpath="$(_module_convert_relative_path "$m")"
    local has_hook="$(_module_check_hook "$mpath" "$hook")"

    if [[ "$has_hook" == "true" ]]; then
      "$_MODULE_CURRENT_DIR/../bin/internal/handler.sh" "$mpath" -a hook -h "$hook" -o "$hook_option"
    fi
  done <<< "$loaded_modules"
}

# keytables
_keytables_get_file() {
  local module_path="$1"
  local module_name="$(_module_get_name "$module_path")"
  local custom_keytables_dir_value="$(get_tmux_option "$custom_keytables_dir_option" "$default_custom_keytables_dir")"
  local keytable_file

  if [[ -e "$custom_keytables_dir_value/$module_name.xml" ]]; then
    keytable_file="$custom_keytables_dir_value/$module_name.xml"
  elif [[ -e "$_PENMUX_KEYTABLES_DIR/$module_name.xml" ]]; then
    keytable_file="$_PENMUX_KEYTABLES_DIR/$module_name.xml"
  else
    keytable_file=""
  fi

  echo "$keytable_file"
}

_keytables_get_prefixkey() {
  local keytable_file="$1"

  xmlstarlet sel -t -v "/PenmuxModuleKeytable/PrefixKey/text()" "$keytable_file"
}

_keytables_get_keys() {
  local keytable_file="$1"

  xmlstarlet sel -t -v "/PenmuxModuleKeytable/Key/Key/text()" "$keytable_file"
}

_keytables_get_key_func() {
  local keytable_file="$1"
  local key="$2"

  xmlstarlet sel -t -v "/PenmuxModuleKeytable/Key[Key=\"$key\"]/Func/text()" "$keytable_file"
}

_keytables_get_key_description() {
  local keytable_file="$1"
  local key="$2"

  xmlstarlet sel -t -v "/PenmuxModuleKeytable/Key[Key=\"$key\"]/Description/text()" "$keytable_file"
}

# api stuff
_module_get_api_version() {
  local module_path="$1"

  "$_MODULE_CURRENT_DIR/../bin/internal/handler.sh" "$module_path" -a apiver
}

_module_has_api() {
  local module_path="$1"
  local required_api="$2"
  local module_api="$(_module_get_api_version "$module_path")"

  # module api is matching actual api -> everything is fine
  [[ "$module_api" == "$API_VERSION" ]] && return 0

  local rmajor="$(echo "$required_api" | cut -d"." -f1)"
  local rminor="$(echo "$required_api" | cut -d"." -f2)"
  local rmicro="$(echo "$required_api" | cut -d"." -f3)"
  local mmajor="$(echo "$module_api" | cut -d"." -f1)"
  local mminor="$(echo "$module_api" | cut -d"." -f2)"
  local mmicro="$(echo "$module_api" | cut -d"." -f3)"

  [[ "$mmajor" -eq "$rmajor" ]] || return 1
  [[ "$mminor" -ge "$rminor" ]] || return 1

  return 0
}

_module_api_compatible() {
  local module_path="$1"
  local required_api="$2"
  local module_api="$(_module_get_api_version "$module_path")"

  # module api is matching actual api -> everything is fine
  [[ "$module_api" == "$API_VERSION" ]] && return 0

  local rmajor="$(echo "$required_api" | cut -d"." -f1)"
  local rminor="$(echo "$required_api" | cut -d"." -f2)"
  local rmicro="$(echo "$required_api" | cut -d"." -f3)"
  local mmajor="$(echo "$module_api" | cut -d"." -f1)"
  local mminor="$(echo "$module_api" | cut -d"." -f2)"
  local mmicro="$(echo "$module_api" | cut -d"." -f3)"

  [[ "$mmajor" -eq "$rmajor" ]] || return 1
  [[ "$mminor" -le "$rminor" ]] || return 2

  return 0
}
