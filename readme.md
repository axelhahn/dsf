# DSF

Axel Hahn wrote a tool to deploy a set of files to multiple targets.

You can use this copy tool if you have some low level classes that are in use in 
several projects or a global css file / favicon/ any other global file to be
applied to a new/ existing project.

## Features

This is a cli tool.

* it handles multiple sources (aka. profiles) that can have multiple source files that need to be updated in multiple local target dirs
* new sources, files or targets will be detected and can be added interactively
* transforms parameters to a full path internally; you always can use relative pathes from any working directory
* get an overview: listing function to see all known projects and its files and projects
* interactive mode for rollout: select source and target interactively from a list of known items
* if source file is older than target you get a diff and can abort the rollout
* scan usages of the current directory in sources and targets

## Hint: Execute from everywhere

Type `echo $PATH` to see current directories of executed files without naming its path.
In one of these directories create a wrapper file:

```shell
> cat >/home/axel/bin/dsf
#!/bin/bash
/home/axel/sources/bash/deploy_sourcefiles/dsf.sh $*

> chmod 755 /home/axel/bin/dsf
```