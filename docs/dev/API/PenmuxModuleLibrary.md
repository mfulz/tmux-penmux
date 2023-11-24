# PenmuxModuleLibrary (scripts/penmux/inc.sh)

Library that provides penmux functions to the modules

## Overview

This library must be used in all penmux modules so that
they can interact with each other and work together with
the penmux API.

It has the following function blocks:
* penmux module functions: Used to read and set options, parse penmux xml files, etc.
* general helper functions: These functions provide csv parsing, tmux path expansion, etc.

## Index

* [penmux_module_get_exported_options](#penmuxmodulegetexportedoptions)
* [penmux_module_set_exported_option](#penmuxmodulesetexportedoption)
* [penmux_module_copy_exported_options](#penmuxmodulecopyexportedoptions)
* [penmux_module_get_option](#penmuxmodulegetoption)
* [penmux_module_set_option](#penmuxmodulesetoption)
* [penmux_module_notify_consumers](#penmuxmodulenotifyconsumers)
* [penmux_module_expand_options_string](#penmuxmoduleexpandoptionsstring)
* [penmux_module_is_loaded](#penmuxmoduleisloaded)
* [penmux_csv_to_arrays](#penmuxcsvtoarrays)
* [penmux_arrays_to_csv](#penmuxarraystocsv)
* [penmux_expand_tmux_format_path](#penmuxexpandtmuxformatpath)

## penmux module functions

The following functions can be used to handle penmux module specific stuff.

### <a name="penmuxmodulegetexportedoptions"></a>penmux_module_get_exported_options

This function will return all options that are exported or not Private
from all loaded modules.

This function will return the options as an array in the format array[ModuleName:OptionName] = value
Most of the modules should not care about all exported options but for some specific modules
like Session it is crucial to retrieve all exported options.

This function will only return options that are exported (when private) and not volatile options.
It is meant for using in modules to provide the possibility for persisting sessions.

#### Example

```bash
declare -A exported_options="$(penmux_module_get_exported_options "$pane_id")"
```

#### Arguments

* **$1** (string): The ID of the tmux pane that requests the exported options

#### Output on stdout

* Output either "" or the options as parsable array string

### <a name="penmuxmodulesetexportedoption"></a>penmux_module_set_exported_option

This function will set an exported option.
It is meant to be used by modules to restore persisted options (like Session) and provides a way
to set options for other modules, wich normally should not be allowed.

It will only set options for loaded modules. This avoids polluting the tmux env with
options not used and keep a cleaner state.

#### Example

```bash
penmux_module_set_exported_options "$pane_id" "Session:SessionDir" "$HOME")"
```

#### Arguments

* **$1** (string): The ID of the tmux pane that requests the exported options
* **$2** (string): The option key, which is in the format ModuleName:OptionName
* **$3** (string): The value for the exported option

### <a name="penmuxmodulecopyexportedoptions"></a>penmux_module_copy_exported_options

This function will copy all options (including volatile) except private only
ones (that should only be used internally by a module for keeping its state) from one pane
to another one.

It is meant to be used by modules like Session, to keep track of the active environment
when creating new panes, etc.

#### Example

```bash
penmux_module_copy_exported_options "$pane_id" "$src_pane_id")"
```

#### Arguments

* **$1** (string): The ID of the destination tmux pane
* **$2** (string): The ID of the source tmux pane

### <a name="penmuxmodulegetoption"></a>penmux_module_get_option

This function will return the value for a requested option.
The requested option must either belong to the calling module or it has
to be defined as Consumer for the module when it is an external option.
Only non private options can be retrieved from external modules.

#### Example

```bash
option_value="$(penmux_module_get_option "$module_file" "SessionDir" "$pane_id")"
```

#### Arguments

* **$1** (string): The absolute path to the module xml definition file
* **$2** (string): The name of the option that is requested (as defined in the xml file)
* **$3** (string): The ID of the tmux pane that requests the option

#### Output on stdout

* Output either "" (if no default value found), the default value or the actual value that was set by the user

### <a name="penmuxmodulesetoption"></a>penmux_module_set_option

This function will set a value for a requested option.
The requested option must  belong to the calling module.

#### Example

```bash
penmux_module_set_option "$module_file" "HttpPort" "80" "$pane_id"
```

#### Arguments

* **$1** (string): The absolute path to the module xml definition file
* **$2** (string): The name of the option that is should be set (as defined in the xml file)
* **$3** (string): The new value that should be set
* **$4** (string): The ID of the tmux pane which option should be set

#### Exit codes

* **0**: If successful
* **1**: If an error happend

#### Output on stderr

* Output an error that describes what went wrong on error

### <a name="penmuxmodulenotifyconsumers"></a>penmux_module_notify_consumers

This function will notify all loaded modules that
has a consumer for this option and not flagged it NoNotify about
the change.

The requested option must  belong to the calling module and flagged 
Provided. Further it must not be flagged Private.

#### Example

```bash
penmux_module_notify_consumers "$module_file" "SessionDir" "$pane_id"
```

#### Arguments

* **$1** (string): The absolute path to the module xml definition file
* **$2** (string): The name of the option that was set
* **$3** (string): The ID of the tmux pane which set the option

#### Exit codes

* **0**: If successful
* **1**: If option is private
* **2**: If option is not provided

### <a name="penmuxmoduleexpandoptionsstring"></a>penmux_module_expand_options_string

This function will expand a given string by replacing
penmux format specifiers

It will use penmux_module_get_option internally so all the rules
for retrieving an option will match here too.

#### Example

```bash
final_command="$(penmux_module_expand_options_string "$module_file" "###SessionDir###mymodule" "$pane_id")"
```

#### Arguments

* **$1** (string): The absolute path to the module xml definition file
* **$2** (string): The input string that should be expanded
* **$3** (string): The ID of the tmux pane where the options should be read from

#### Output on stdout

* Outputs the expanded input string

### <a name="penmuxmoduleisloaded"></a>penmux_module_is_loaded

This function tells if a module is loaded

#### Example

```bash
loaded="$(penmux_module_is_loaded "auxilliary/Session.xml")"
if [[ "$loaded" == "yes" ]]; then
  do anything when module is loaded
else
  do anything when module is not loaded
fi
```

#### Arguments

* **$1** (string): The path to the module xml relative to the module search path

#### Output on stdout

* Outputs yes if module is loaded or "" when it is not loaded

## general helper functions

The following functions can be used to for general recurring tasks.

### <a name="penmuxcsvtoarrays"></a>penmux_csv_to_arrays

This function parse a given csv content and print parsable lines
that can be assigned to arrays.

The lines will contain an array with the heading columns as key and the
matching column content as value.

#### Example

```bash
csv_content="$(cat input.csv)"
csv_parsed="$(penmux_csv_to_arrays "$csv_content")"
while IFS= read -r e; do
  declare -A earr="($(echo "$e"))"
done <<< "$csv_parsed"
```

#### Arguments

* **$1** (string): The content from the csv file
* **$2** (char): A separator. This is optional and ',' will be used when not given

#### Output on stdout

* Output either "" or the parsed csv data

### <a name="penmuxarraystocsv"></a>penmux_arrays_to_csv

This function parse a given array content and
print the corresponding csv content.

#### Example

```bash
csv_parsed="$(penmux_csv_to_arrays "$csv_content")"
csv_content="$(penmux_arrays_to_csv "$csv_parsed")"
echo "$csv_content" > output.csv
```

#### Arguments

* **$1** (string): The content of the csv like array
* **$2** (char): A separator. This is optional and ',' will be used when not given

#### Output on stdout

* Output either "" or the parsed csv data

### <a name="penmuxexpandtmuxformatpath"></a>penmux_expand_tmux_format_path

This function will expand a given string by replacing
tmux format specifiers

#### Example

```bash
final_path="$(penmux_expand_tmux_format_path "$pane_id" "%H-#S.log")"
```

#### Arguments

* **$1** (string): The ID of the tmux pane where the options should be read from
* **$2** (string): The input string that should be expanded
* **$3** (boolean): If the path should be kept relative

#### Output on stdout

* Outputs the expanded input string

