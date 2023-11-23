# Commander Module

This module is providing an interface to execute commands which can use various penmux options (not restricted to this module) as paramters, flags, etc. so that you don't have to mess around with boring stuff.

It can be extended by csv files with new commands as you like and has some dumb replacement parser to use dynamic values from penmux options, etc.
Further it will also read sh files from the configured 'CommandSearchPath', which can provide more complicated functionality than simple commands.

## 1. Keytable

Not implemented.

## 2. Options

The following configurable options are used by the Session module.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
|CommandSearchPath | String | $HOME/.tmux/plugins/tmux-penmux/modules/auxiliary/Commander/commands | The search path for csv files providing commands |
|NoConfirm | Boolean | false | If this option is true the selected command will be send to the tmux pane including enter, so that it will run directly |
|RemoteHost | String | 127.0.0.1 | An option used by various commands. Can be seen like metasploit's RHOST |
|RemotePort | Integer | 80 | An option used by various commands. Can be seen like metasploit's RPORT |
|RemoteProto | String | http | An option used by various commands. A.e.: gobuster will use this for the target url |
|LocalHost | String | 127.0.0.1 | An option used by various commands. Can be seen like metasploit's LHOST |
|LocalPort | Integer | 4444 | An option used by various commands. Can be seen like metasploit's LPORT |
|LocalTempPort | Integer | 8800 | An option that can be used by Commander commands internally for temporary communication |

## 3. Adding commands

You can extend the Commander with commands to your like. Either by extending existing csv files or creating new ones. The module is loading any csv or sh file from the 'CommandSearchPath' recursively so that they can be grouped by using nested directories.

**If you're adding any commands, please create an issue / pr so that others can benefit from**

### Needed files

For a new group of commands, you need to create two files (csv and desc) under any sub folder inside the 'CommandSearchPath' directory.
It has an empty custom folder that should be used for custom commands and is not included in the git source.

Follow these steps to create a new command group (default configuration):
```
mkdir -p $HOME/.tmux/plugins/tmux-penmux/modules/auxiliary/Commander/commands/custom/my/new/group
touch $HOME/.tmux/plugins/tmux-penmux/modules/auxiliary/Commander/commands/custom/my/new/group/sub.csv
echo "My sub group provides some cool stuff" $HOME/.tmux/plugins/tmux-penmux/modules/auxiliary/Commander/commands/custom/my/new/group/sub.desc
```
The csv format is using just ',' as separator and contains the following columns:
| name | description | path | restart | command |
|------|-------------|------|---------|---------|
|Unique name which is shown in the selector | A description of what the command is doing | A path that should be created. Used to store files, etc. and **should** always reference to the session directory (see TODO). Leave empty if no path should be created | true or false. If true the command will be surrounded by an infinite loop to restart | The command, which is to be executed |

As example checkout the nmap group under 'auxiliary/scanners'

nmap.desc (this is the description shown by the selection window):
```
Predefined list of nmap portscanner commands that can be used against a target
```
nmap.csv (this is the csv file containing the command definitions):
```
name,description,path,restart,command
tcpAllDefault,Default nmap tcp scan including standard scripts for all ports,###SessionDir###nmap,false,nmap -sC -sV -p- -oN ###SessionDir###nmap/###RemoteHost###-%Y%m%d%H%M%S-tcpAllDefault ###RemoteHost###
tcpDefault,Default nmap tcp scan including standard scripts for default ports,###SessionDir###nmap,false,nmap -sC -sV -oN ###SessionDir###nmap/###RemoteHost###-%Y%m%d%H%M%S-tcpDefault ###RemoteHost###
tcpAllDefaultNoHost,Default nmap tcp scan including standard scripts for all ports without host discovery,###SessionDir###nmap,false,nmap -Pn -sC -sV -p- -oN ###SessionDir###nmap/###RemoteHost###-%Y%m%d%H%M%S-tcpAllDefaultNoHost ###RemoteHost###
tcpDefaultNoHost,Default nmap tcp scan including standard scripts for default ports without host discovery,###SessionDir###nmap,false,nmap -Pn -sC -sV -oN ###SessionDir###nmap/###RemoteHost###-%Y%m%d%H%M%S-tcpDefaultNoHost ###RemoteHost###
udpAllDefault,Default nmap udp scan including standard scripts for all ports,###SessionDir###nmap,false,sudo nmap -sU -sV -p- -oN ###SessionDir###nmap/###RemoteHost###-%Y%m%d%H%M%S-udpAllDefault ###RemoteHost###
udpDefault,Default nmap udp scan including standard scripts for default ports,###SessionDir###nmap,false,sudo nmap -sU -sV -oN ###SessionDir###nmap/###RemoteHost###-%Y%m%d%H%M%S-udpAllDefault ###RemoteHost###
udpAllDefaultNoHost,Default nmap udp scan including standard scripts for all ports without host discovery,###SessionDir###nmap,false,sudo nmap -Pn -sU -sV -p- -oN ###SessionDir###nmap/###RemoteHost###-%Y%m%d%H%M%S-udpAllDefaultNoHost ###RemoteHost###
udpDefaultNoHost,Default nmap udp scan including standard scripts for default ports without host discovery,###SessionDir###nmap,false,sudo nmap -Pn -sU -sV -oN ###SessionDir###nmap/###RemoteHost###-%Y%m%d%H%M%S-udpAllDefaultNoHost ###RemoteHost###
vulnAllDefault,Default nmap scan for vulnerabilities,###SessionDir###nmap,false,nmap --script vuln -oN ###SessionDir###nmap/###RemoteHost###-%Y%m%d%H%M%S-vulnAllDefault ###RemoteHost###
vulnPortDefault,Default nmap scan for vulnerabilities against the remote port,###SessionDir###nmap,false,nmap --script vuln -p ###RemotePort### -oN ###SessionDir###nmap/###RemoteHost###-###RemotePort###-%Y%m%d%H%M%S-vulnPortDefault ###RemoteHost###
vulnAllDefaultNoHost,Default nmap scan for vulnerabilities without host discovery,###SessionDir###nmap,false,nmap --script vuln -Pn -oN ###SessionDir###nmap/###RemoteHost###-%Y%m%d%H%M%S-vulnAllDefaultNoHost ###RemoteHost###
vulnPortDefaultNoHost,Default nmap scan for vulnerabilities against the remote port without host discovery,###SessionDir###nmap,false,nmap --script vuln -Pn -p ###RemotePort### -oN ###SessionDir###nmap/###RemoteHost###-###RemotePort###-%Y%m%d%H%M%S-vulnPortDefaultNoHost ###RemoteHost###
```

### Braking it down

Let's check out one line to get an idea on what is going on:
```
tcpAllDefault,Default nmap tcp scan including standard scripts for all ports,###SessionDir###nmap,false,nmap -sC -sV -p- -oN ###SessionDir###nmap/###RemoteHost###-%Y%m%d%H%M%S-tcpAllDefault ###RemoteHost###
```
- The first part `tcpAllDefault` is just the selector name shown to the user.
- The second part `Default nmap tcp scan including standard scripts for all ports` is just the description of what the command will do shown to the user.
- The third part `###SessionDir###nmap` is the path, which has to be created (if not already existing) as the command will store files. The special tags `###SessionDir###` are replaced by the session directory if using the Session module and a session is loaded. If not it will be empty and a folder `nmap` will be created in the current working directory. **Don't add a `/` after the `###SessionDir###` as it would lead to a subdir under `/` if not working inside a session.
- The forth part `false` will define if the command is surrounded by a infinite loop, so that it will be restarted if finished.
- The last part `nmap -sC -sV -p- -oN ###SessionDir###nmap/###RemoteHost###-%Y%m%d%H%M%S-tcpAllDefault ###RemoteHost###` is where the real work is happening. It will start nmap with the provided arguments.

### Replacement / Expanding

For detailed information of what can be added as dynamic values please refer to [String replacements](../misc/Replacements.md)

## 4. Development information

**TODO**
