SUPPORTED_VERSION="1.9"

# Defaults
# Pathes
la_default_work_dir="$HOME"
la_global_work_dir=$(tmux show-option -gqv "@la-work-dir")
la_work_dir=$(tmux show-option -qv "@la-work-dir")
la_work_dir=${la_work_dir:-$la_global_work_dir}
la_work_dir=${la_work_dir:-$la_default_work_dir}

#la_default_session_path="${la_work_dir}/#{session_name}/%Y%m%dT%H"
la_default_session_path="${la_work_dir}/#{session_name}"
la_session_path=$(tmux show-option -gqv "@la-session-path")
la_session_path=${la_session_path:-$la_default_session_path}

la_default_log_path="${la_session_path}/#{window_name}"
la_log_path=$(tmux show-option -gqv "@la-log-path")
la_log_path=${la_log_path:-$la_default_log_path}

la_default_screenshot_path="${la_session_path}/#{window_name}"
la_screenshot_path=$(tmux show-option -gqv "@la-screenshot-path")
la_screenshot_path=${la_screenshot_path:-$la_default_screenshot_path}

# General options
la_default_capture_via_script=1
la_capture_via_script=$(tmux show-option -gqv "@la-capture-via-script")
la_capture_via_script=${la_capture_via_script:-$la_default_capture_via_script}

la_default_script_timing=1
la_script_timing=$(tmux show-option -gqv "@la-script-timing")
la_script_timing=${la_script_timing:-$la_default_script_timing}

la_log_suffix="#{pane_title}/%Y%m%dT%H%M%S.log"
la_screenshot_suffix="#{pane_title}/%Y%m%dT%H%M%S.png"

# Binaries
la_default_scrot_bin="/usr/bin/scrot"
la_scrot_bin=$(tmux show-option -gqv "@la-scrot-bin")
la_scrot_bin=${la_scrot_bin:-$la_default_scrot_bin}

# Key bindings
la_default_logging_key="P" # Shift-p
la_logging_key=$(tmux show-option -gqv "@la-logging-key")
la_logging_key=${la_logging_key:-$la_default_logging_key}

la_default_pane_screen_capture_key="C-p" # Ctrl-p
la_pane_screen_capture_key=$(tmux show-option -gqv "@la-screen-capture-key")
la_pane_screen_capture_key=${la_pane_screen_capture_key:-$la_default_pane_screen_capture_key}

la_default_save_complete_history_key="C-P" # Ctrl-Shift-p
ls_save_complete_history_key=$(tmux show-option -gqv "@la-save-complete-history-key")
la_save_complete_history_key=${la_save_complete_history_key:-$la_default_save_complete_history_key}

la_default_clear_history_key="C-c" # Ctrl-c
la_clear_history_key=$(tmux show-option -gqv "@la-clear-history-key")
la_clear_history_key=${la_clear_history_key:-$la_default_clear_history_key}

# Logging options

la_default_log_filename="${la_log_suffix}"
la_log_filename=$(tmux show-option -gqv "@la-log-suffix")
la_log_filename=${la_log_filename:-$la_default_log_filename}

la_log_full_filename="${la_log_path}/${la_log_filename}"

# Screen capture options
la_default_screenshot_filename="${la_screenshot_suffix}"
la_screenshot_filename=$(tmux show-option -gqv "@la-screenshot-filename")
la_screenshot_filename=${la_screenshot_filename:-$la_default_screenshot_filename}

la_screenshot_full_filename="${la_screenshot_path}/${la_screenshot_filename}"
