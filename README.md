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

#### Standard modules

**TODO**

### Tasks by PRIO

- [x] Migrate Repo
- [ ] Installation / Usage Documentation
- [ ] Stabilizing API
- [ ] Development / Contribution Documentation

### Configuration Docs

- [Core configuration](docs/configuration_core.md).
- [Modules configuration](docs/configuration_modules.md).

### License

[MIT](LICENSE.md)
