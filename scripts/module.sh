_CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$_CURRENT_DIR/helpers.sh"

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

_module_get_handlescript() {
  local module_path="${1}"

  xmlstarlet sel -t -v '/PenmuxModule/HandleScript' -n "${module_path}"
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

  xmlstarlet sel -t -v "/PenmuxModule/Option/Name/text()" "$module_path"
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

_module_get_option_default_value() {
  local module_path="$1"
  local option_name="$2"
  local module_name="$(_module_get_name "$module_path")"
  local custom_module_options_dir_value="$(get_tmux_option "$custom_module_options_dir_option" "$default_custom_module_options_dir")"
  local options_file
  local option_default

  if [[ -e "$custom_module_options_dir_value/$module_name.xml" ]]; then
    options_file="$custom_module_options_dir_value/$module_name.xml"
  fi

  if [[ -n "$options_file" ]]; then
    option_default="$(xmlstarlet sel -t -v "/PenmuxModuleOptions/Option[Name=\"$option_name\"]/DefaultValue" "$options_file")"
  fi

  if [[ -n "$option_default" ]]; then
    echo "$option_default"
  else
    xmlstarlet sel -t -v "/PenmuxModule/Option[Name=\"$option_name\"]/DefaultValue" "$module_path"
  fi
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
      handle_script="$_PENMUX_MODULE_DIR/$(_module_get_handlescript "$act_module_path")"

      [ -z "$handle_script" ] && continue
      if [ -z "$opt_value" ]; then
        "$handle_script" -c "$_CURRENT_DIR" -a optionsnotify -m "$act_module_path" -p "$pane_id" -k "$opt_name" -s "$opt_volatile"
      else
        "$handle_script" -c "$_CURRENT_DIR" -a optionsnotify -m "$act_module_path" -p "$pane_id" -k "$opt_name" -s "$opt_volatile" -i "$opt_value"
      fi
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
