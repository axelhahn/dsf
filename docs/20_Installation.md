# Installation

The script is useful in the user of the current desktop user context only.
It is highly recommended to extract the script as the user you logged in on desktop.

## Get the files

### Git

Go to any directory and start

`git clone https://github.com/axelhahn/dsf.git`

This creates the subdir "dsf".

### OR: Zip archive

* Download <https://github.com/axelhahn/dsf/archive/refs/heads/master.zip> 
* extract it with `unzip master.zip`. This creates the subdir "dsf-master".
* rename dsf-master into dsf

## Structure

After the installation you have such a filestructure:

```txt
|-- docs
|-- dsf.sh
|-- profiles
|   `-- .gitkeep
`-- readme.md
```

## Execute it from everywhere

Type `echo $PATH` to see current directories of executed files without naming its path.
In one of these directories create a wrapper file. 

In this example I create a file below my \$HOME/bin. with a simple cat command that redirects to my new file.
The wrapper contains 2 lines 

* the shebang and 
* the full path of the bash script dsf.sh ... followed by `$*`.

```shell
> cat >/home/axel/bin/dsf
#!/bin/bash
[Installdir]/dsf.sh $*
```
Then you need to make the file executable.

```shell
> chmod 750 /home/axel/bin/dsf
```

Finally: test it.
By typing `dsf` in the terminal you get a short output suggesting the parameter `-h`.
