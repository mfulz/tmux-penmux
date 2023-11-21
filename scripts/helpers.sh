SUPPORTED_VERSION="1.9"

_CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_PENMUX_MODULE_SCHEMA="${_CURRENT_DIR}/../schemas/penmux-module.xsd"
_PENMUX_MODULE_DIR="${_CURRENT_DIR}/../modules"
_PENMUX_KEYTABLES_DIR="${_CURRENT_DIR}/../keytables"

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
	local option="$1"
	local default_value="$2"
	local pane_id="$3"
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
