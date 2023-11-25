# Module Development Guide

This guide is meant to be a tutorial for developing a penmux module. It will guide you through all API features and details about their effects and use cases.

## 1. Introduction

The penmux module API is (hopefully) evolving in the future and therefore changes (even backward compatibility breaking ones) could happen if they're required. To keep everything work together in a way to have the least compatibility issues the API is using a versioning schema that is explained now.

The API version is using a schema that is build of the format: "major version"."minor version"."micro version" (ae.: 1.0.0). To have a clear understanding about the compatibility the following rules are applied on version updates (this is meant to be for version updates of the API and not the tmux-penmux itself).

This means tmux-penmux could be any version (like 2.4.20) and the API could be any different version (like 1.4.1). To get an understanding how this could happen, let's think about adding modules to penmux should increasing the version of the software but not of the API, as there are no changes for it.

The following rules are applied to match the compatibility of the API:

- If the major version differs there are to many or to heavy changes and the module will be rejected to load or used by penmux
- If the minor version differs there will be two cases that could be happen:
  - The API version is higher than the module version: This will lead to a working module but there are new features to check out and the module should be updated to not get incompatible in the future
  - The API version is lower than the module version: This will lead to reject the module to load or used as it is using features that the API is not providing
- If the micro version differs there is nothing to worry about, as it means that the module and API are compatible. It could still be that the [Module Handler Boilerplate](#penmuxmoduleinc) got some changes (normally just cleanups, code improvements, etc.) and should be adopted by the module

## 2. Module structure

Modules are build by using a flat structure on the filesystem. They have to be placed under the `modules` folder inside the tmux-penmux source code and can be use any level on nested folders.
This folders are just used as a way to group modules together for easier searching / selecting, etc. Inside the `modules` folder there is a folder named `custom` which should be used for custom modules that are not going to be included in the tmux-penmux release itself.

**There are very rare cases that would reject a module to be merged into the code** so please think about to share your work so the community will profit from it, too ;) checkout the [Contribution Guide](../ContributionGuide.md) for more information.

The module is build up from different files and must have as minimum a xml file, which is describing the module ([PenmuxModuleSchema](../API/schemas/PenmuxModule.md)).

The second file, that is required is the [penmux_module_inc.sh](#penmux_module_inc) that must be placed in a folder in the same path as the xml file named exactly like the module file without extension. This file provides the entry points to be used by the API and therefore by penmux.

Optional files a module can have are used for default options and keytables. These files are placed under `options` and `keytables` folders inside the tmux-penmux source code or at their regarding custom folders (see [Readme](../../../README.md)).

The options default values is described by a xml file, which is following the [PenmuxModuleOptions](../API/schemas/PenmuxModuleOptions.md) schema.

The keytable is described by a xml file, which is following the [PenmuxModuleKeytable](../API/schemas/PenmuxModuleKeytable.md) schema.

### Example of a module

Here will put the above together and create the folder and files required to build our module.

We will assume that penmux is installed into `$HOME/.tmux/plugins/tmux-penmux` and the `options` and `keytable` paths are the defaults pointing to `$HOME/.tmux/penmux/options` and `$HOME/.tmux/penmux/keytables`

Therefore the following commands has to be executed:
```
# creating the module core
mkdir -p "$HOME/.tmux/plugins/tmux-penmux/modules/custom/MyCustomModule"
touch "$HOME/.tmux/plugins/tmux-penmux/modules/custom/MyCustomModule.xml"

# creating the module optional files
mkdir -p "$HOME/.tmux/penmux/options
mkdir -p "$HOME/.tmux/penmux/keytables
touch "$HOME/.tmux/penmux/options/MyCustomModule.xml"
touch "$HOME/.tmux/penmux/keytables/MyCustomModule.xml"
```

**If a module is going to be merged upstream it should be placed under modules not using custom and the options and keytables should be placed under the folders inside the tmux-penmux source root**

## 3. Module Metadata

This chapter will guide you through the metadata and boilerplate that a module is build of.

### 3.1 Module description

To define what API features a module is using and what it provides (options, provides, keytable, etc.) we have to fill the `modules/custom/MyCustomModule.xml` regarding the [Module Description](../API/schemas/PenmuxModule.md):

```
<?xml version="1.0" encoding="UTF-8"?>
<PenmuxModule xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="../../schemas/penmux-module.xsd">
  <Name>MyCustomModule</Name>
  <Description>Module that shows how to develop a penmux module</Description>
  <CmdPrio>10000</CmdPrio>
  <HasRun>true</HasRun>
  <NotifyOptions>true</NotifyOptions>
  <Option xsi:type="OptionTypeBool" Private="true" Exported="true">
    <Name>PrivateExportedBool</Name>
    <Description>If this option is enabled it does not make any difference</Description>
  </Option>
  <Option xsi:type="OptionTypeString" Private="true">
    <Name>PrivateString</Name>
    <Description>This option is private only string example that should only be used as internal holder for temporary data</Description>
  </Option>
  <Option xsi:type="OptionTypeInt">
    <Name>GlobalInt</Name>
    <Description>This option is for global usage and can be defined by multiple modules</Description>
  </Option>
  <Option xsi:type="OptionTypeString" Private="true" Exported="true" Volatile="true">
    <Name>VolatileExample</Name>
    <Description>This option is meant to be used like an private and exported option with the difference that is not given by requesting exported options, as it should not be persistet</Description>
  </Option>
  <Option xsi:type="OptionTypeString" Provided="true">
    <Name>ProvidedString</Name>
    <Description>A provided option is meant to be used by other modules for various purposes. It cannot be set to a value and is a result of computing happening inside the module</Description>
  </Option>
  <Consumes NoNotify="true">
    <Name>SessionDir</Name>
    <From>Session</From>
  </Consumes>
  <Consumes>
    <Name>ProvidedString</Name>
    <From>MyCustomModule</From>
  </Consumes>
  <Hooks>
    <PreModuleUnload>true</PreModuleUnload>
  </Hooks>
</PenmuxModule>
```

This module description will use all features to get an understanding on how to use them and what use cases they are intended to fulfill.

We will get into the details in the following chapters when we're going to implement the example module.

### 3.2 Module Options Default Values

The Module can have default values for the options that can be set by the user. Therefore we'll have to edit the `$HOME/.tmux/penmux/options/MyCustomModule.xml` file and create the following content:

```
<?xml version="1.0" encoding="UTF-8"?>
<PenmuxModuleOptions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="../schemas/penmux-module-options.xsd">
  <Option>
    <Name>PrivateExportedBool</Name>
    <DefaultValue>false</DefaultValue>
  </Option>
  <Option>
    <Name>GlobalInt</Name>
    <DefaultValue>12345</DefaultValue>
  </Option>
  <Option>
    <Name>VolatileExample</Name>
    <DefaultValue>My Value is not for persisting</DefaultValue>
  </Option>
  <Option>
    <Name>ProvidedString</Name>
    <DefaultValue>Im something other modules want to use</DefaultValue>
  </Option>
</PenmuxModuleOptions>
```

In this file we can provide module defaults that a user can override. For modules included in the penmux source a user would normally just copy the option xml from `options` to the custom options directory and adjust them to his needs.

Lets explain why we left out some options which doesn't get any default values.
If you inspect the details about the options not included into the options, you should realize that they are restricted:

- Options that are private only cannot be set by a user, so it doesn't make any sense to let them have values as they are meant to keep track of internal states about the module itself, that are not interesting for any other modules and doesn't make sense to store by session modules as the state has to be defined by software execution and not by setting values to options.

- Provided options match basically the same explanation as the private only ones. The difference is that these options are intended to be used by other modules for various features by active notifying consumers about a change. They are also computed by the module and not set by the user, so there is no sense to set any defaults.

- Consumers are the counterpart of provided and therefore just received from other modules. They can't have any values set as they're just for requesting values from external.

We'll see what all that means in a practical way later during the implementation.

### 3.3. Module Keytable

If a module has user callable functions it has to provide a keytable so that they can be used. Therefore we've to edit the `$HOME/.tmux/penmux/keytables/MyCustomModule.xml` and create the following content:

```
<?xml version="1.0" encoding="UTF-8"?>
<PenmuxModuleKeytable xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="../schemas/penmux-module-keytable.xsd">
  <PrefixKey>m</PrefixKey>
  <Key>
    <Key>t</Key>
    <Func>test</Func>
    <Description>Shows what a keytable is doing with the keys</Description>
  </Key>
</PenmuxModuleKeytable>
```

This xml file is basically just a replacement table so that a module can run the correct function on a keypress. The rules to apply this are the following:

- The PrefixKey is used as a module prefix that works analog the tmux `prefix` key. It must be pressed after the penmux keytable-key (see [README](../../../README.md)) and after this the defined keys will execute the modules function on a press.

- The Key is a mapping that will send the module the `Func` that is requested.

We'll see more about how that works in detail during the implementation.

## 4. Implementation

In this chapter we'll see how to implement the module's functionality (focused on the penmux API) and how it works together with other modules.

### 4.1 Penmux Handler

To get a module usable by the API we've to implement the handler functions which are provided as directly usable script. Therefore we copying the `penmux_module_inc.sh` script into our module folder:
```
cp $HOME/.tmux/plugins/tmux-penmux/docs/modules/penmux_module_inc.sh $HOME/.tmux/plugins/tmux-penmux/modules/custom/MyCustomModule/
```

The following code is the core interface that the API uses to interact with our module:
```
#!/usr/bin/env bash

### Module handler interface ###
# Has to be implemented by every module

_PENMUX_INC_CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Basic suggestion to used module shared functions
#source "$_PENMUX_INC_CURRENT_DIR/shared.sh"

# _PENMUX_SCRIPTS will point to full path of script/penmux (can be used for sourcing inc.sh)
# _MODULE_FILE will point to full path of the module xml file

_load() {
  return
}

_unload() {
  return
}

_run() {
  local "$pane_id"

  return
}

_cmd() {
  local calling_pane_id="$1"
  local pane_id="$2"

  return
}

_optionsnotify() {
  local pane_id="$1"
  local opt="$2"
  local val="$3"
  local volatile="$4"

  return
}

_consumes() {
  local pane_id="$1"
  local opt="$2"
  local val="$3"

  return
}

_keyfunc() {
  local calling_pane_id="$1"
  local pane_id="$2"
  lcoal func_name="$3"

  case "$func_name" in
    *)
      echo >&2 "Unknown func name: '$func_name'"
      ;;
  esac

  return
}

_hook() {
  local pane_id="$1"
  local hook="$2"
  local hook_option="$3"

  case "$hook" in
    "PreModuleLoad")
      ;;
    "PostModuleLoad")
      ;;
    "PreModuleUnload")
      ;;
    "PostModuleUnload")
      ;;
    *)
      echo >&2 "Unknown hook name: '$hook'"
      ;;
  esac

  return
}

_apiver() {
  # do not change this without implementing the
  # required changes
  echo "1.0.0"
}
```
