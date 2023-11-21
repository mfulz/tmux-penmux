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

**TODO**

#### Installation with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add plugin to the list of TPM plugins in `.tmux.conf`:

    set -g @plugin 'tmux-plugins/tmux-penmux'

Hit `prefix + I` to fetch the plugin and source it.

You should now have all `tmux-penmux` key bindings defined.

#### Manual Installation

Clone the repo:

    $ git clone https://github.com/mfulz/tmux-penmux ~/clone/path

Add this line to the bottom of `.tmux.conf`:

    run-shell ~/clone/path/logging.tmux

Reload TMUX environment:

    # type this in terminal
    $ tmux source-file ~/.tmux.conf

You should now have all `tmux-penmux` key bindings defined.

### 2. Usage

This chapter descripes how to use this plugin and it's modules. It will give an overview of the standard modules
that are included and how to use them.

#### Core Plugin

**TODO**

#### Standard modules

**TODO**

### 1. Tasks by PRIO

- [x] Migrate Repo
- [ ] Installation / Usage Documentation
- [ ] Stabilizing API
- [ ] Development / Contribution Documentation

### Configuration Docs

- [Core configuration](docs/configuration_core.md).
- [Modules configuration](docs/configuration_modules.md).

### License

[MIT](LICENSE.md)
