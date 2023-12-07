#!/usr/bin/env bash

PT_CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$PT_CURRENT_DIR/scripts/include/variables.sh"
source "$PT_CURRENT_DIR/scripts/penmux/inc.sh"


main() {
  # local pane_id="$(tmux display-message -p "#D")"
  local keytable_key_option_value="$(get_tmux_option "$keytable_key_option" "$default_keytable_key")"
  local load_module_key_option_value="$(get_tmux_option "$load_module_key_option" "$default_load_module_key")"
  local unload_module_key_option_value="$(get_tmux_option "$unload_module_key_option" "$default_unload_module_key")"
  local change_option_key_option_value="$(get_tmux_option "$change_option_key_option" "$default_change_option_key")"
  local run_key_value="$(get_tmux_option "$run_key_option" "$default_run_key")"
  tmux bind -T prefix "$keytable_key_option_value" switch-client -T penmux_keytable
	tmux bind -T penmux_keytable "$load_module_key_option_value" run-shell "$PT_CURRENT_DIR/scripts/bin/load_module.sh"
	tmux bind -T penmux_keytable "$unload_module_key_option_value" run-shell "$PT_CURRENT_DIR/scripts/bin/unload_module.sh"
	tmux bind -T penmux_keytable "$change_option_key_option_value" run-shell "$PT_CURRENT_DIR/scripts/bin/set_module_options.sh"
	tmux bind -T penmux_keytable "$run_key_value" run-shell "$PT_CURRENT_DIR/scripts/bin/run_module.sh"

  # tmux set-hook -g session-created "run-shell \"$PT_CURRENT_DIR/scripts/bin/internal/init.sh\""
  tmux run-shell "$PT_CURRENT_DIR/scripts/bin/internal/init.sh"
}

main
