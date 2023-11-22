# Tmux Penmux

A tmux plugin that supports penetration testing.

This plugin is by no means any competitor to existing exploit frameworks like metasploit, etc.
It is meant to be a helping hand for pentest sessions including stuff like session management
snippets, reuse, etc. pp.

It is inspired from metasploit's modules and can be extended by modules.

**This is early WIP and the plugin API could change breaking everything ;)**

### 1. Installation

Follow this chapter to install tmux-penmux

#### Requirements

The following tools are required by the core:

- [xmlstarlet](https://xmlstar.sourceforge.net)
- [awk](https://github.com/onetrueawk/awk)
- [sed](https://www.gnu.org/software/sed/)
- [fzf](https://github.com/junegunn/fzf)
- [bash](https://www.gnu.org/software/bash/)

The following tools are used by the standard modules. They are used to provide the core functionality for the modules.
The modules will provide further features, that needs additional tools but these are for the pentesting itself and therefore
not included here:

- [util-linux (script)](https://github.com/util-linux/util-linux)
- [xclip (can be replaced by configuration)](https://sourceforge.net/projects/xclip/)

#### Installation with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add plugin to the list of TPM plugins in `.tmux.conf`:

    set -g @plugin 'mfulz/tmux-penmux'

Hit `prefix + I` to fetch the plugin and source it.

You should now have all `tmux-penmux` key bindings defined.

#### Manual Installation

Clone the repo:

    $ git clone https://github.com/mfulz/tmux-penmux ~/clone/path

Add this line to the bottom of `.tmux.conf`:

    run-shell ~/clone/path/penmux.tmux

Reload TMUX environment:

    # type this in terminal
    $ tmux source-file ~/.tmux.conf

You should now have all `tmux-penmux` key bindings defined.

### 2. Usage

This chapter descripes how to use this plugin and it's modules. It will give an overview of the standard modules
that are included and how to use them.

#### Core

This plugin is basically just an API to provide features via modules. The main features are just loading, unloading, running modules and changing their options.

##### Screencast

![core](https://seafile.olznet.de/f/5589273ff92c4508b6c5/?dl=1)

##### Key bindings

- `prefix + P + l` - load module
- `prefix + P + u` - unload module
- `prefix + P + c` - change module options
- `prefix + P + r` - run module

### 3. Configuration

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

### 4. Modules

| Module | Path | Description |
|--------|------|-------------|
|[Session](docs/modules/auxilliary/Session.md) | auxilliary | Module to handle penmux sessions (persisting options, etc.) |
|[Commander](docs/modules/auxilliary/Commander.md) | auxilliary | Module to run commands that are read from csv fiels |
|[Snipper](docs/modules/auxilliary/Snipper.md) | auxilliary | Module to copy snippets to clipboard that are read from csv fiels |
|[Scriptlog](docs/modules/reporting/Scriptlog.md) | reporting | Module to log all terminal input / output via script |
|[HttpExchange](docs/modules/comm/HttpExchange.md) | comm | Module to provide a python webserver including predifined fetch commands |

### Tasks by PRIO

- [x] Migrate Repo
- [x] Installation / Usage Documentation
- [x] Core configuration Documentation
- [ ] Module usage Documentation
- [ ] Module configuration Documentation
- [ ] Stabilizing API
- [ ] Development / Contribution Documentation

### License

[MIT](LICENSE.md)
