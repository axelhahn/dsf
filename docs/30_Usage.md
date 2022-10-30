## Get help

By adding the `-h` parameter you get a help page.

```txt
> dsf -h
_______________________________________________________________________________

 ▄▄▄▄    ▄▄▄▄  ▄▄▄▄▄   |
 █   ▀▄ █▀   ▀ █       |  DEPLOY
 █    █ ▀█▄▄▄  █▄▄▄▄   |    SOURCE                                       v0.08
 █    █     ▀█ █       |      FILES  ..  to multiple local targets
 █▄▄▄▀  ▀▄▄▄█▀ █       |
 
Axel Hahns helper tool to update local files in other projects.
_______________________________________________________________________________


Copy sourcefiles to one or many targets.
It can be used to handle repository files of low level components or basic
files and update them in multiple projects.


SYNTAX:
dsf.sh [OPTIONS] [FROM] [TO]

OPTIONS:
    -c          compare source and targets; requires -s and -t
    -d [DIR]    add a directory that is below [FROM] directory
    -e          edit a profile; requires -s
    -f [FILE]   add a file that is below [FROM] directory 
                You need to set a source (see -s) before -f
    -h          show this help
    -i          interactive mode to select a source and a target
    -l          list defined sources and its targets
    -s [FROM]   set a source directory (to use -f, -t, -u)
    -t [TO]     set a target for a given source
                You need to set a source (see -s) before -t
    -u          update ALL known targets; [TO] is not required - targets will
                be read from config
                You need to set a source (see -s) before -u
    -w          where is .. something for the current directory?
                Search current directory for definitions in sources or targets

All projects are written as txt file wit md5 hash into "profiles" directory.
    /home/axel/sources/bash/deploy_sourcefiles/profiles
To delete a file or target grep for it in the profiles dir.

EXAMPLES:

Create/ set a source
    dsf.sh -s /home/axel/deployfiles/docs
                -s = set source
                Set a source. If it does not exist yet than a new profile will
                be created interactively.

Add source files and directories
    dsf.sh -s /home/axel/deployfiles/docs -d abc
                -d = add directory
                Add a directory to the project. You get a prompt to add it if it 
                does not exist yet.

    dsf.sh -s /home/axel/deployfiles/docs -f style.css
                -f = add file
                Add a file to the project. You get a prompt to add it if it 
                does not exist yet.

    Hint: You can repeat -d and -f multiple times.

Create/ set target
    dsf.sh -s /home/axel/deployfiles/docs -t /home/projects/project_A
    OR
    dsf.sh /home/axel/deployfiles/docs /home/projects/project_A
                -t = target
                Add a targetdir to the project. You get a prompt to add it if 
                it does not exist yet.
                Then it copies all known files to the target.

Update
    dsf.sh -s /home/axel/deployfiles/docs -u
                -u = update all
                Copy all known files to all known targets.

More:
    dsf.sh -i   Interactive mode to select from known sources and targets.

    dsf.sh -l   list all known projects and show details

    dsf.sh -s /home/axel/deployfiles/docs -l
                -l = list
                list details of selected project

    dsf.sh -w   where is ... search: something for the current directory

```
