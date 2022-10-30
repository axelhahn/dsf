# Features

This is a cli tool written in bash.

* it handles multiple sources (aka. profiles) that can have multiple source files that need to be updated in multiple local target dirs
* new sources, files or targets will be detected and can be added interactively
* transforms parameters to a full path internally; you always can use relative pathes from any working directory
* get an overview: listing function to see all known projects and its files and projects
* interactive mode for rollout: select source and target interactively from a list of known items
* if source file is older than target you get a diff and can abort the rollout
* scan usages of the current directory in sources and targets
