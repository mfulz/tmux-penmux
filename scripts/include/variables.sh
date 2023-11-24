SUPPORTED_VERSION="1.9"
API_VERSION="1.0.0"

# custom keytables path
custom_keytables_dir_option="@penmux-custom-keytables-dir"
default_custom_keytables_dir="$HOME/.tmux/penmux/keytables"

# custom module options path
custom_module_options_dir_option="@penmux-custom-module-options-dir"
default_custom_module_options_dir="$HOME/.tmux/penmux/options"

# The modules listed will be autoloaded by the penmux plugin
autoload_modules_option="@penmux-autoload-modules"

# Key bindings
keytable_key_option="@penmux-keytable-key" # Shift-p
default_keytable_key="P"

load_module_key_option="@penmux-load-module-key" # l
default_load_module_key="l"

unload_module_key_option="@penmux-unload-module-key" # u
default_unload_module_key="u"

change_option_key_option="@penmux-change-option-key" # c
default_change_option_key="c"

run_key_option="@penmux-run-key" # r
default_run_key="r"
