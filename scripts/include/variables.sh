SUPPORTED_VERSION="1.9"
API_VERSION="1.0.0"

# custom keytables path
custom_keytables_dir_option="@penmux-custom-keytables-dir"
default_custom_keytables_dir="$HOME/.tmux/penmux/keytables"

# custom module options path
custom_module_options_dir_option="@penmux-custom-module-options-dir"
default_custom_module_options_dir="$HOME/.tmux/penmux/options"

# Enable autoloading for modules
# Set to any value to enable autoloading of modules
enable_autoload_option="@penmux-enable-autoload"
default_enable_autoload=""

# The modules listed will be autoloaded by the penmux plugin
# The modules need to be given by relative path starting from the
# modules dir and separated by space (ae. auxiliary/Session.xml auxiliary/Snipper.xml)
autoload_modules_option="@penmux-autoload-modules"
default_autoload_modules="auxiliary/Session.xml auxiliary/Commander.xml auxiliary/Snipper.xml comm/HttpExchanger.xml payloads/msfvenom.xml"

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
