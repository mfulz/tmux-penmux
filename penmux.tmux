#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/scripts/variables.sh"
source "$CURRENT_DIR/scripts/exported.sh"


main() {
  local session="$(tmux display-message -p "#{session_id}")"
  local pane_id="$(tmux display-message -p "#D")"
  local keytable_key_option_value="$(get_tmux_option "$keytable_key_option" "$default_keytable_key")"
  local load_module_key_option_value="$(get_tmux_option "$load_module_key_option" "$default_load_module_key")"
  local unload_module_key_option_value="$(get_tmux_option "$unload_module_key_option" "$default_unload_module_key")"
  local change_option_key_option_value="$(get_tmux_option "$change_option_key_option" "$default_change_option_key")"
  tmux bind -T prefix "$keytable_key_option_value" switch-client -T penmux_keytable
	tmux bind -T penmux_keytable "$load_module_key_option_value" run-shell "$CURRENT_DIR/scripts/load_module.sh"
	tmux bind -T penmux_keytable "$unload_module_key_option_value" run-shell "$CURRENT_DIR/scripts/unload_module.sh"
	tmux bind -T penmux_keytable "$change_option_key_option_value" run-shell "$CURRENT_DIR/scripts/set_module_options.sh"
}

main
