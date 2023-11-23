# Session Module

This module provides persistent sessions for penmux. It has somehow a special part, as it is interacting with all other modules
and got some specific features implemented in the API.

Nevertheless it is using only API functionality, so it could be exchanged with another module, if someone has a need for it.

## 1. Keytable

The following keys are defined by the Session module. Keep in mind, that you've to use tmux prefix + penmux prefix + module prefix + module key to run the function. A.e.: `prefix + P + s + n` for a new session with default config.

| Func | Default | Description |
|--------|---------|-------------|
|prefix | s | This is the module specific prefix key |
|new | n | Create a new session |
|exit | e | Exit a session |
|load | l | Load a session |
|save | s | Save a session |

## 2. Options

The following configurable options are used by the Session module.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
|AutoLoad | Boolean | true | If this option is true sessions are automatically loaded from .pmses files. To use this feature you have to add some configuration to your shell (see [Optional Configuration](#cdconf)) |
|AutoSave | Boolean | true | If this option is true sessions are automatically saved to .pmses files when options are changed |
|NoConfirm | Boolean | false | If this option is true new sessions will silently overwrite already existing session files |
|UseCwd | Boolean | true | If this option is true a new session will be created as a sub directory (session name) of the current working dir. They will be created under the SessionDirBase if not |
|SessionDirBase | String | $HOME/.tmux/penmux/sessions | The directory to store session files, if not using cwd |

## <a name="cdconf"></a>3. Optional configuration

This module provides a script that needs to be used as an shell alias, if you want to use the auto loading feature. You can find it under 'modules/auxilliary/Session/exports/cd.sh'.

To enable it you need to source it in your shell rc file and create an alias. Further you should check if you're in a tmux session and only then configure it.

As example for zsh you can do the following:
```
vim ~/.zshrc
```
Add the following (depending on your installation you need to adjust the paths):
```
# penmux
if [[ -n "$TMUX" ]]; then
  source "/home/mfulz/.tmux/plugins/tmux-penmux/modules/auxiliary/Session/exports/cd.sh"
  alias cd="cd_session"
fi
```
This will alias the 'cd' command to use the provided Session function, that will automatically load sessions if you've loaded the session module.

## 4. Development information

**TODO**
