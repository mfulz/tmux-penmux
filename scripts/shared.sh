get_tmux_option() {
    local option=$1
    local default_value=$2
    local option_value=$(tmux show-option -gqv "$option")
    if [ -z "$option_value" ]; then
        echo $default_value
    else
        echo $option_value
    fi
}

# Ensures a message is displayed for 3 seconds in tmux prompt
display_message() {
    local PANE_ID="${1}"
    local message="${2}"

    # display_duration defaults to 3 seconds, if not passed as an argument
    if [ "$#" -eq 3 ]; then
        local display_duration=${3}
    else
        local display_duration="3000"
    fi

    # saves user-set 'display-time' option
    local saved_display_time=$(get_tmux_option "display-time" "750")

    # displays message
    tmux display-message -d "${display_duration}" -t "${PANE_ID}" "$message"
}

# simplest solution, taken from here: http://unix.stackexchange.com/a/81689
remove_empty_lines_from_end_of_file() {
    local file=$1
    local temp=$(cat $file)
    printf '%s\n' "$temp" > "$file"
}

supported_tmux_version_ok() {
    $CURRENT_DIR/check_tmux_version.sh "$SUPPORTED_VERSION"
}

# Checking full path to logfile and expanding tmux format in normal path
# As example: expand %Y-%m-%d to current date
expand_tmux_format_path() {
    local PANE_ID="${1}"
    local tmux_format_path="${2}"
    local full_path=$(tmux display-message -t "${PANE_ID}" -p "${tmux_format_path}")
    local full_directory_path=${full_path%/*}
    mkdir -p "${full_directory_path}"
    echo "${full_path}"
}

ansifilter_installed() {
    type ansifilter > /dev/null 2>&1 || return 1
}

script_installed() {
    type script > /dev/null 2>&1 || return 1
}

use_script() {
    if [[ ${la_capture_via_script} -ne 0 ]]; then
        return $(script_installed)
    fi
    return 1
}

use_timing() {
    if [[ ${la_script_timing} -ne 0 ]]; then
        return 0
    fi
    return 1
}
