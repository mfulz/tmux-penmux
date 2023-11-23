# ScriptLog Module

This module will log all terminal input and output via script. It is meant to have a complete documentation of the terminal sessions
and what was done.

## 1. Keytable

Not implemented.

## 2. Options

The following configurable options are used by the Commander module.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
|LogExisting | Boolean | true | If this option is enabled all existing panes will respawn starting script for logging. If not just new ones will start logging |
|Name | String | %Y%m%d-#T-(#D).log | The naming for log files. Every tmux formats can be used |
|LogPenmuxSessionDir | Boolean | true | If enabled it will use the session directory (if working inside a session) and log inside a subfolder 'scriptlog' |
|LogDir | String | $HOME/.tmux/penmux/scriptlog/#S | The default directory used to log into (if no session or LogPenmuxSessionDir is false). Every tmux formats can be used |

### Replacement / Expanding

For detailed information of what can be added as dynamic values please refer to [String replacements](../misc/Replacements.md)

## 3. Development information

**TODO**
