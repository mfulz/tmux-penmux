# Configuration of the Core

## Directories

| Config | Default | Description |
|--------|---------|-------------|
|`set -g @penmux-custom-keytables-dir "$HOME/.tmux/penmux/keytables"` | $HOME/.tmux/penmux/keytables | This directory can hold keytable definitions for modules to override the defaults |
|`set -g @penmux-custom-module-options-dir "$HOME/.tmux/penmux/keytables"` | $HOME/.tmux/penmux/options | This directory can hold option definitions for modules to override the defaults |

## Keybindings

| Config | Default | Description |
|--------|---------|-------------|
|`set -g @penmux-keytable-key "P"` | P | This is the prefix key for penmux |
|`set -g @penmux-load-module-key "l"` | l | Load module |
|`set -g @penmux-unload-module-key "u"` | u | Unload module |
|`set -g @penmux-change-option-key "c"` | c | Change module options |
|`set -g @penmux-run-key "r"` | r | Run module |
