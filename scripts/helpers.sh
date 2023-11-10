SUPPORTED_VERSION="1.9"

_CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_PENMUX_MODULE_SCHEMA="${_CURRENT_DIR}/../schemas/penmux-module.xsd"
_PENMUX_MODULE_DIR="${_CURRENT_DIR}/../modules"

supported_tmux_version_ok() {
	"$_CURRENT_DIR/check_tmux_version.sh" "$SUPPORTED_VERSION"
}

# env and option helpers
get_tmux_option_global() {
	local option=$1
	local default_value=$2
	local pane_id=$3
	local option_value

  if [ -z "$pane_id" ]; then
    pane_id="$(tmux display-message -p "#D")"
  fi

  option_value=$(tmux show-options -t "$pane_id" -gqv "$option")

	if [ -z "$option_value" ]; then
		echo $default_value
	else
		echo $option_value
	fi
}

get_tmux_option_session() {
	local option=$1
	local default_value=$2
	local pane_id=$3
	local option_value

  if [ -z "$pane_id" ]; then
    pane_id="$(tmux display-message -p "#D")"
  fi

  option_value=$(tmux show-options -t "$pane_id" -qv "$option")

	if [ -z "$option_value" ]; then
		echo $default_value
	else
		echo $option_value
	fi
}

get_tmux_option_window() {
	local option=$1
	local default_value=$2
	local pane_id=$3
	local option_value

  if [ -z "$pane_id" ]; then
    pane_id="$(tmux display-message -p "#D")"
  fi

  option_value=$(tmux show-options -t "$pane_id" -wqv "$option")

	if [ -z "$option_value" ]; then
		echo $default_value
	else
		echo $option_value
	fi
}

get_tmux_option_pane() {
	local option=$1
	local default_value=$2
	local pane_id=$3
	local option_value

  if [ -z "$pane_id" ]; then
    pane_id="$(tmux display-message -p "#D")"
  fi

  option_value=$(tmux show-options -t "$pane_id" -pqv "$option")

	if [ -z "$option_value" ]; then
		echo $default_value
	else
		echo $option_value
	fi
}

get_tmux_option() {
	local option=$1
	local default_value=$2
	local pane_id=$3
	local option_value

  if [ -z "$pane_id" ]; then
    pane_id="$(tmux display-message -p "#D")"
  fi

	option_value=$(get_tmux_option_pane "$option" "" "$pane_id")
	[[ -z "$option_value" ]] || {
		echo $option_value
		return
	}
	option_value=$(get_tmux_option_window "$option" "" "$pane_id")
	[[ -z "$option_value" ]] || {
		echo $option_value
		return
	}
	option_value=$(get_tmux_option_session "$option" "" "$pane_id")
	[[ -z "$option_value" ]] || {
		echo $option_value
		return
	}
	option_value=$(get_tmux_option_global "$option" "" "$pane_id")
	[[ -z "$option_value" ]] || {
		echo $option_value
		return
	}
	echo $default_value
}

# Handlers to work around tmux limitations
unset_tmux_hook() {
  local hook="$1"
  local cmd="$2"
  local session="$3"
  local all_hooks

  if [ -z "$session" ]; then
    session="$(tmux display-message -p "#S")"
  fi

  all_hooks="$(tmux show-hooks -t "$session" | grep "$hook" | grep -v "$cmd" | awk '{$1=""; print $0}')"

  tmux set-hook -t "$session" -u "$hook"
  while IFS= read -r h; do
    [ -z "$h" ] && continue
    [[ "$h" == " " ]] && continue
    tmux set-hook -t "$session" -a "$hook" "$h"
  done <<< "$all_hooks"
}

# Checking full path to logfile and expanding tmux format in normal path
# As example: expand %Y-%m-%d to current date
expand_tmux_format_path() {
  local pane_id="$1"
	local tmux_format_path="${2}"
	local full_path=$(tmux display-message -t "$pane_id" -p "${tmux_format_path}")
  echo "$full_path" | sed "s,\$HOME,$HOME,g; s,\$HOSTNAME,$(hostname),g; s,\~,$HOME,g"
}

# path helpers

session_cwd() {
	local session_cwd_option_value="$(get_tmux_option "$session_cwd_option" "")"
	[ -n "$session_cwd_option_value" ]
}

penmux_session_dir() {
  local session_name
  local path
	if [ -z "$_PENMUX_SESSION_DIR" ]; then
    session_name="$(tmux display-message -p '#S')"
    if session_cwd; then
      path="$(pwd)/$session_name"
    else
      path="$(get_tmux_option "$penmux_session_dir_option" "$default_penmux_session_dir")/$session_name"
    fi
		echo "$path" | sed "s,\$HOME,$HOME,g; s,\$HOSTNAME,$(hostname),g; s,\~,$HOME,g"
	else
		echo "$_PENMUX_SESSION_DIR"
	fi
}
_PENMUX_SESSION_DIR="$(penmux_session_dir)"

penmux_log_dir() {
	local log_task_option_value="$(get_tmux_option "$log_task_option" "")"
  local task_name_option_value="$(get_tmux_option "$task_name_option" "")"
  local session_dir
  local path
  session_dir="$(penmux_session_dir)"

  if [ -z "$log_task_option_value" ]; then
    path="$session_dir/logs"
  else
    if [ -n "$task_name_option_value" ]; then
      path="$session_dir/$task_name_option_value"
    else
      path="$session_dir/logs"
    fi
  fi
  echo "$path"
}

penmux_log_file() {
  local log_dir="$(penmux_log_dir)"
  local logfile_name_option_value="$(get_tmux_option "$logfile_name_option" "$default_logfile_name")"

  echo "$log_dir/$logfile_name_option_value"
}

# general helpers
penmux_use_script() {
  local dont_use_script_option_value="$(get_tmux_option "$dont_use_script_option" "")"
  [ -z "$dont_use_script_option_value" ]
}

penmux_log_script_timing() {
  local script_no_timing_option_value="$(get_tmux_option "$script_no_timing_option" "")"
  [ -z "$dont_use_script_option_value" ]
}

penmux_list_session_panes() {
  local session_name="${1}"
  tmux list-panes -aF '#D' -f "#{==:#S,"${session_name}"}"
}

# module stuff
penmux_module_validate() {
  local module_path="${1}"

  err=$(xmlstarlet val --xsd "${_PENMUX_MODULE_SCHEMA}" "${module_path}" 2>&1 >/dev/null) || { echo "${err}"; return 1; }
}

penmux_module_get_name() {
  local module_path="${1}"

  xmlstarlet sel -t -v '/PenmuxModule/Name' -n "${module_path}"
}

penmux_module_get_description() {
  local module_path="${1}"

  xmlstarlet sel -t -v '/PenmuxModule/Description' -n "${module_path}"
}

penmux_module_get_handlescript() {
  local module_path="${1}"

  xmlstarlet sel -t -v '/PenmuxModule/HandleScript' -n "${module_path}"
}

penmux_module_get_uses() {
  local module_path="${1}"

  xmlstarlet sel -t -v '/PenmuxModule/Use' -n "${module_path}"
}

penmux_module_get_depends() {
  local module_path="${1}"

  xmlstarlet sel -t -v '/PenmuxModule/Depend' -n "${module_path}"
}

penmux_module_get_cmdprio() {
  local module_path="${1}"

  xmlstarlet sel -t -v '/PenmuxModule/CmdPrio' -n "${module_path}"
}

penmux_module_get_options() {
  local module_path="$1"

  xmlstarlet sel -t -v "/PenmuxModule/Option/Name/text()" "$module_path"
}

penmux_module_get_option_private() {
  local module_path="$1"
  local option_name="$2"

  xmlstarlet sel -t -v "boolean(/PenmuxModule/Option[Name=\"$option_name\"]/@Private)" "$module_path"
}

penmux_module_get_option_exported() {
  local module_path="$1"
  local option_name="$2"

  xmlstarlet sel -t -v "boolean(/PenmuxModule/Option[Name=\"$option_name\"]/@Exported)" "$module_path"
}

penmux_module_get_option_description() {
  local module_path="$1"
  local option_name="$2"

  xmlstarlet sel -t -v "/PenmuxModule/Option[Name=\"$option_name\"]/Description/text()" "$module_path"
}

penmux_module_get_option_default_value() {
  local module_path="$1"
  local option_name="$2"

  xmlstarlet sel -t -v "/PenmuxModule/Option[Name=\"$option_name\"]/DefaultValue" "$module_path"
}

penmux_module_convert_relative_path() {
  local relative_path="$1"
  echo "$_PENMUX_MODULE_DIR/$relative_path"
}

penmux_module_get_loaded() {
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

penmux_module_is_loaded() {
  local module="$1"
  local loaded_modules="$(penmux_module_get_loaded)"

  while IFS= read -r m; do
    if [[ "$module" == "$m" ]]; then
      return 0
    fi
  done <<< "$loaded_modules"

  return 1
}

penmux_module_get_exported_options() {
  local pane_id="$1"
  local loaded_modules="$(penmux_module_get_loaded)"
  local opts_arr
  declare -A opts_arr

  while IFS= read -r m; do
    mpath="$(penmux_module_convert_relative_path "$m")"
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

  # xmlstarlet val sel -t -c "/PenmuxModule/Option[Name=\"$option_name\"]" "${module_path}" >/dev/null || { echo ""; return 1; }

  option_private="$(xmlstarlet sel -t -v "boolean(/PenmuxModule/Option[Name=\"$option_name\"]/@Private)" "$module_path")"
  module_name="$(xmlstarlet sel -t -v "/PenmuxModule/Name" "$module_path")"

  if [ "$option_private" == "true" ]; then
    tmux_option_name="@penmux-$module_name-$option_name"
  else
    tmux_option_name="@penmux-$option_name"
  fi

  if [ -z "$value" ]; then
    tmux set-option -t "$pane_id" -p -u "$tmux_option_name"
  else
    tmux set-option -t "$pane_id" -p "$tmux_option_name" "$value"
  fi
}

penmux_module_notify_consumers() {
  local module_path="${1}"
  local provider_name="${2}"
  local pane_id="${3}"
  local loaded_modules="$(penmux_module_get_loaded)"
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
    act_module_path="$(penmux_module_convert_relative_path "$m")"
    consumes="$(xmlstarlet sel -t -v "/PenmuxModule/Consumes[Name=\"$provider_name\"]/Name/text()" "$act_module_path")"
    if [ -n "$consumes" ]; then
      handle_script="$_PENMUX_MODULE_DIR/$(penmux_module_get_handlescript "$act_module_path")"

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
