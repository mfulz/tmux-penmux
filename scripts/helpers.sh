if [ -d "$HOME/.tmux/penmux" ]; then
	default_penmux_session_dir="$HOME/.tmux/penmux"
else
	default_penmux_session_dir="${XDG_DATA_HOME:-$HOME/.local/share}"/tmux/penmux
fi
penmux_session_dir_option="@penmux-session-dir"

SUPPORTED_VERSION="1.9"
PENMUX_SESSION_FILE_PREFIX="tmux_penmux"
PENMUX_SESSION_FILE_EXTENSION="pses"
_PENMUX_SESSION_DIR=""
_PENMUX_SESSION_FILE_PATH=""

_PENMUX_MODULE_SCHEMA="${CURRENT_DIR}/../schemas/penmux-module.xsd"
_PENMUX_MODULE_DIR="${CURRENT_DIR}/../modules"

supported_tmux_version_ok() {
	"$CURRENT_DIR/check_tmux_version.sh" "$SUPPORTED_VERSION"
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
  module_name="$(xmlstarlet sel -t -v "/PenmuxModule/@Name" "$module_path")"

  if [ "$option_private" == "true" ]; then
    tmux_option_name="@penmux-$module_name-$option_name"
  else
    tmux_option_name="@penmux-$option_name"
  fi

  get_tmux_option "$tmux_option_name" "$option_default"
}

penmux_module_convert_relative_path() {
  local relative_path="$1"
  echo "$_PENMUX_MODULE_DIR/$relative_path"
}
