# Tmux Penmux

A tmux plugin that supports penetration testing.

This plugin is by no means any competitor to existing exploit frameworks like metasploit, etc.
It is meant to be a helping hand for pentest sessions including stuff like session management
snippets, reuse, etc. pp.

It is inspired from metasploit's modules and can be extended by modules.

**This is early WIP ~~and the plugin API could change breaking everything ;)~~**

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

This chapter describes how to use this plugin and it's modules. It will give an overview of the standard modules
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

#### Directories

| Config | Default | Description |
|--------|---------|-------------|
|`set -g @penmux-custom-keytables-dir "$HOME/.tmux/penmux/keytables"` | $HOME/.tmux/penmux/keytables | This directory can hold keytable definitions for modules to override the defaults |
|`set -g @penmux-custom-module-options-dir "$HOME/.tmux/penmux/options"` | $HOME/.tmux/penmux/options | This directory can hold option definitions for modules to override the defaults |

#### Keybindings

| Config | Default | Description |
|--------|---------|-------------|
|`set -g @penmux-keytable-key "P"` | P | This is the prefix key for penmux |
|`set -g @penmux-load-module-key "l"` | l | Load module |
|`set -g @penmux-unload-module-key "u"` | u | Unload module |
|`set -g @penmux-change-option-key "c"` | c | Change module options |
|`set -g @penmux-run-key "r"` | r | Run module |

### 4. Modules

The modules are providing the functionality for penmux. Therefore the core is providing a basic API / Guideline to let the modules work in a cooperative way to *hopefully* provide usable features to other users and not only myself ;)

#### Basic Configuration

The modules can have two type of files, that let the user configure them.

##### Options

The first type are the general options, that a module has. If you want to adjust the default values for a module, you copy the module's options xml from options/moduleName.xml to the penmux-custom-module-options-dir (default: $HOME/.tmux/penmux/options) and adjust them to your needs.

As an example if you want to change the default directory to store sessions for the Session module, you would do the following:
```
mkdir -p $HOME/.tmux/penmux/options
cp $HOME/.tmux/plugins/tmux-penmux/options/Session.xml $HOME/.tmux/penmux/options/
```

Then change the line for the "SessionDirBase" from:
```
<Option>
    <Name>SessionDirBase</Name>
    <DefaultValue>$HOME/.tmux/penmux/sessions</DefaultValue>
</Option>
```
to your likes:
```
<Option>
    <Name>SessionDirBase</Name>
    <DefaultValue>$HOME/my/new/penmux/session/folder</DefaultValue>
</Option>
```

##### Keytables

If a module has some functions that are bound to keys it has a file under keytables/moduleName.xml. To adjust the default keys for the module you have to copy the keytable xml to the penmux-custom-keytables-dir (default: $HOME/.tmux/penmux/keytables).

**Not all modules are using keytables**

As an example if you want to change the default keys for creating a new session for the Session module, you would do the following:
```
mkdir -p $HOME/.tmux/penmux/keytables
cp $HOME/.tmux/plugins/tmux-penmux/keytables/Session.xml $HOME/.tmux/penmux/keytables/
```
Then change the key for 'new' from:
```
<Key>
  <Key>n</Key>
  <Func>new</Func>
  <Description>Creates a new session</Description>
</Key>
```
to your likes:
```
<Key>
  <Key>t</Key>
  <Func>new</Func>
  <Description>Creates a new session</Description>
</Key>
```

The 'PrefixKey' is used as a module prefix. It can be changed to your likes, too.
That means that if you want to run any module functions you would need to use the tmux prefix + penmux prefix + module prefix + module function key.

As example to create a new session with all defaults you would press: `prefix + P + s + n`

#### Standard modules

| Module | Path | Runnable | Description |
|--------|------|----------|-------------|
|[Session](docs/modules/auxilliary/Session.md) | auxilliary | No | Module to handle penmux sessions (persisting options, etc.) |
|[Commander](docs/modules/auxilliary/Commander.md) | auxilliary | Yes | Module to run commands that are read from csv files |
|[Snipper](docs/modules/auxilliary/Snipper.md) | auxilliary | Yes |Module to copy snippets to clipboard that are read from csv files |
|[ScriptLog](docs/modules/reporting/ScriptLog.md) | reporting | No | Module to log all terminal input / output via script |
|[HttpExchange](docs/modules/comm/HttpExchange.md) | comm | Yes | Module to provide a python webserver including predifined fetch commands |

### 5. Development

Here you can find the guides for developing modules.

#### API

- The [Penmux Module Library](docs/dev/API/PenmuxModuleLibrary.md) should be used to interact with Options and other penmux modules.
- The [Penmux Schemas](docs/dev/API/PenmuxSchemas.md) are describing what a module is made from
- The [Module Development Guide](docs/dev/modules/ModuleDevelopmentGuide.md) teaches how to write modules

### Tasks by PRIO

- [x] Migrate Repo
- [x] Installation / Usage Documentation
- [x] Core configuration Documentation
- [x] Module usage Documentation
- [x] Module configuration Documentation
- [x] Stabilizing API
- [x] Development Info 
- [ ] Module development Guide
- [ ] Contribution Guide

### License

[MIT](LICENSE.md)
