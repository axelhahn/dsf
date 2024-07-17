#!/usr/bin/env bash
# ======================================================================
#
# deploy filesets to multiple targets
#
# ----------------------------------------------------------------------
# requires
# - realpath
# - rsync
# ----------------------------------------------------------------------
# 2022-08-xx  v0.01   axel hahn  first lines...
# 2022-08-26  v0.02   axel hahn  add diff 
# 2022-08-27  v0.03   axel hahn  fix option -f; add dir; update listing
# 2022-08-27  v0.04   axel hahn  support searchterm for source and target
# 2022-08-28  v0.05   axel hahn  add dirs: sync+diff
# 2022-08-30  v0.06   axel hahn  add edit functionality; write config
# 2022-09-25  v0.07   axel hahn  add where is (param -w)
# 2022-10-30  v0.08   axel hahn  clearify results of -w param
# 2022-10-30  v0.08   axel hahn  clearify results of -w param
# 2022-11-02  v0.09   axel hahn  show -h on no prams; show info if no profile exists
# 2022-11-16  v0.10   axel hahn  show config file per profile; test vi if EDITOR is not set
# 2022-12-20  v0.11   axel hahn  add param -W that does the same like -w but shows diffs
# 2024-07-20  v0.12   axel hahn  highlight current dir in path selection; add param -S; autodetect target on source seelction
# ======================================================================

DSF_SELFDIR="$( dirname $0 )"

# ----------------------------------------------------------------------
# CONFIG
# ----------------------------------------------------------------------

DSF_PROFILES=${DSF_SELFDIR}/profiles
DSF_CONFIG=
DSF_SOURCE=
DSF_TARGET=
DSF_VERSION=0.12

DSF_WORKDIR="$( realpath . )"

# ----------------------------------------------------------------------
# private
# ----------------------------------------------------------------------


# set a terminal color by a keyword
# param  string  keyword to set a color; one of reset | head|cmd|input | ok|warning|error | h2|h3 | key
function color(){
    local sColorcode=""
    case $1 in
        "reset") sColorcode="0"
                ;;
        "head")  sColorcode="33" # yellow
                ;;
        "cmd")   sColorcode="94" # light blue
                ;;
        "input") sColorcode="92" # green
                ;;
        "ok") sColorcode="92" # green
                ;;
        "warning") sColorcode="33" # yellow
                ;;
        "error") sColorcode="91" # red
                ;;
        "h2") sColorcode="1;33" # yellow
                ;;
        "h3") sColorcode="33" # yellow
                ;;
        "key") sColorcode="04m\e[07" # reverse
                ;;
    esac
    if [ ! -z ${sColorcode} ]; then
        echo -ne "\e[${sColorcode}m"
    fi    
}

# echo a colored text and reset color
# param  string  keyword to set a color - see function color() above
# param  string  text to show
function cecho(){
    color $1
    shift
    echo $*
    color reset
}

function showPrompt(){
    color input
    echo -n "$*"
    color reset
}

function h2(){
    echo; cecho "h2" "========== $*"
}
function h3(){
    echo; cecho "h3" "----- $*"
}
function key(){
    color key
    echo -n "$*"
    color reset
}
# get a relative target filename 
# used in _fileupdate
#
# param  string  relative filename to $DSF_SOURCE
function _getTargetfile(){
    local _relfile="$1"
    local _newfile=${_relfile//.dist/}
    echo "$_newfile"
}
# Sync a source (sub)folder to a target
# used in _copy
#
# param  string  relative folder to $DSF_SOURCE to sync
function _foldersync(){

    # relative filename of source
    local _relfile="$1"

    # echo "FROM: $_myfile"
    h3 "Sync folder $_relfile ==> ${DSF_TARGET}/$_relfile"

    echo -n "rsync ... "
    set -vx
    rsync -rav "${DSF_SOURCE}/$_relfile/" "${DSF_TARGET}/$_relfile" || exit 2
    set +vx
    echo "OK"

}

# Update a file or dist file with placeholders
# used in _copy
#
# param  string  relative filename to $DSF_SOURCE to sync
function _fileupdate(){

    # relative filename of source
    local _relfile="$1"

    # absolute filename
    local _myfile="${DSF_SOURCE}/$_relfile"

    # relative filename of target
    # local _newfile=${_relfile//.dist/}
    local _newfile
    _newfile=$( _getTargetfile "$_relfile" )

    # echo "FROM: $_myfile"
    h3 "Updating $DSF_TARGET/$_newfile"

    # echo -n "Update $_myfile $DSF_TARGET/$_newfile ... "
    # exit 1

    if [ "$_relfile" = "$_newfile" ]; then
        if [ "$_myfile" -ot "$DSF_TARGET/$_newfile" ]; then
            if ! diff "$_myfile" "$DSF_TARGET/$_newfile" >/dev/null; then
                echo "WARNING: target file is newer than source"
                diff -y --suppress-common-lines -N --color "$DSF_TARGET/$_newfile" "$_myfile" # | sed "s#^#  #g"
                showPrompt "press Ctrl + C to stop or RETURN to continue"
                read -r dummy
            fi
        fi

        echo -n "rsync ... "
        rsync "$_myfile" "$DSF_TARGET/$_newfile" || exit 2
        echo "OK"
    else
        if [ ! -f "$DSF_TARGET/$_newfile" ]; then
            echo -n "copy dist ... "
            cp "$_myfile" "$DSF_TARGET/$_newfile" || exit 2
            echo "OK"
        else
            echo "already exists - SKIP "
        fi
        echo -n "  check placeholders: "
        if grep '"__[A-Z]*__' "$DSF_TARGET/$_newfile" >/dev/null
        then
            echo "FOUND: Please edit the file."
            grep '"__[A-Z]*__' "$DSF_TARGET/$_newfile" 
        else
            echo "None. OK."
        fi
    fi

}

# start to deploy FILES to DSF_TARGET
function _copy(){
    local myfile=
    # h2 "DEPLOY files to $DSF_TARGET"
    if [ "$DSF_TARGET" = "ALL" ]; then
        _copytoalltargets
    else
        for mydir in $( getFolders )
        do
            _foldersync "${mydir}"
        done
        for myfile in $( getFiles )
        do
            _fileupdate "${myfile}"
        done
    fi
}

# start to deploy to all targets
# called from _copy if the target is the keyword "ALL"
function _copytoalltargets(){
    # h2 "UPDATE ALL TARGETS"
    for mytarget in $( getTargets )
    do
        targetSet "${mytarget}"
        _copy
    done
}

# start to deploy FILES to DSF_TARGET
function _diff(){
    local myfile=
    local _newfile=


    local bak_DSF_SOURCE="$DSF_SOURCE"
    local bak_DSF_TARGET="$DSF_TARGET"
    
    test -n "$1" && sourceSet "$1" >/dev/null 2>&1
    test -n "$2" && targetSet "$2" >/dev/null 2>&1

    if [ "$DSF_TARGET" = "ALL" ]; then
        for mytarget in $( getTargets )
        do
            targetSet "${mytarget}" >/dev/null
            _diff
        done
    else
        echo
        h2 "COMPARE ${DSF_SOURCE} <-> ${DSF_TARGET}"

        for mydir in $( getFolders )
        do
            h3 "Folder: ${mydir}"
            echo "FROM ${DSF_SOURCE}/${mydir}" 
            echo "TO   ${DSF_TARGET}/${mydir}"
            color cmd
            ls -ld "${DSF_SOURCE}/${mydir}" "${DSF_TARGET}/${mydir}"
            echo
            diff -y --suppress-common-lines -N --color -r "${DSF_TARGET}/${mydir}" "${DSF_SOURCE}/${mydir}"
            color reset
        done

        for myfile in $( getFiles )
        do
            _newfile=$( _getTargetfile "$myfile" )
            h3 "File: ${myfile}"
            if ! diff "${DSF_TARGET}/${_newfile}" "${DSF_SOURCE}/${myfile}" >/dev/null 2>&1; then
                ls -l --sort=none "${DSF_SOURCE}/${myfile}" | sed "s#^#FROM #"
                ls -l "${DSF_TARGET}/${_newfile}"           | sed "s#^#TO   #"
                echo
                diff -y --suppress-common-lines -N --color "${DSF_TARGET}/${_newfile}" "${DSF_SOURCE}/${myfile}"
            else
                echo "Up to date."
            fi
        done
    fi
    DSF_SOURCE="$bak_DSF_SOURCE"
    DSF_TARGET="$bak_DSF_TARGET"
}

function _editconfig(){
    h2 "EDIT config"
    if [ -z "${DSF_CONFIG}" ]; then
        echo "Set a source first."
    else
        if [ -z "$EDITOR" ]; then
            echo "INFO: The variable EDITOR was not set. Trying vi(m)..."
            which vi  >/dev/null 2>&1 && export EDITOR=vi
            which vim >/dev/null 2>&1 && export EDITOR=vim
        fi
        if [ -z "$EDITOR" ]; then
            echo "SKIP: The editor VI was not found."
        else
            echo "INFO: Starting $EDITOR ${DSF_CONFIG} ..."
            $EDITOR "${DSF_CONFIG}"
            _updateConfig
        fi
    fi
}

function _whereis(){
    local _doDiff="$1"
    local _bFound=0

    h2 "Where is something for me?"
    echo
    echo -n "scanning for ${DSF_WORKDIR} ..."
    echo
    local filelist="${DSF_CONFIG}"
    test -z "$filelist" && filelist="${DSF_PROFILES}/*.txt"

    # echo
    # echo "--- scan in sources"
    echo
    for myprofile in $( ls -1 $filelist 2>&1 )
    do
        sourcedir=$( grep 'SOURCE=' "$myprofile" | sed 's#^SOURCE=##g' | sort )
        if echo "${DSF_WORKDIR}" | grep "$sourcedir" >/dev/null
        then
            if [ -z "$_doDiff" ]; then
                color ok
                echo "> SOURCE $sourcedir" | grep --colour "${sourcedir}"
                color reset
                echo
            else
                _diff "$sourcedir" "ALL"
            fi
            _bFound=1
        else
            if echo "$sourcedir" | grep "${DSF_WORKDIR}" >/dev/null
            then
                if [ -z "$_doDiff" ]; then
                    color ok
                    echo "> SOURCE $sourcedir" | grep --colour "${DSF_WORKDIR}"
                    color reset
                    echo
                else
                    _diff "$sourcedir" "ALL"
                fi
                _bFound=1
            fi
        fi
    done

    # echo "--- scan in targets"
    echo
    for myprofile in $( ls -1 $filelist 2>&1 )
    do
        sourcedir=$( grep 'SOURCE=' "$myprofile" | sed 's#^SOURCE=##g' | sort )
        for mytarget in $( grep 'TARGET=' "$myprofile" | sed 's#^TARGET=##g' | sort )
        do
            if echo "${DSF_WORKDIR}" | grep "$mytarget" >/dev/null
            then
                if [ -z "$_doDiff" ]; then
                    color ok
                    echo "> SOURCE $sourcedir"
                    color reset
                    echo "  \`-> TARGET $mytarget" | grep --colour "${mytarget}"
                else
                    _diff "$sourcedir" "$mytarget"
                fi
                _bFound=1
                echo
            fi
            if echo "$mytarget" | grep "${DSF_WORKDIR}" >/dev/null
            then
                if [ -z "$_doDiff" ]; then
                    color ok
                    echo "> SOURCE $sourcedir"
                    color reset
                    echo "  \`-> TARGET $mytarget" | grep --colour "${DSF_WORKDIR}"
                else
                    _diff "$sourcedir" "$mytarget"
                fi
                _bFound=1
                echo
            fi
        done
    done
    test $_bFound -eq 0 && echo "Nothing was found :-/"
}

# ----------------------------------------------------------------------

# get a list of defined targets
function getFiles(){
    cat "${DSF_CONFIG}" | grep "^FILE=" | cut -f 2- -d "=" | sort
}
# get a list of defined targets
function getFolders(){
    cat "${DSF_CONFIG}" | grep "^DIR=" | cut -f 2- -d "=" | sort
}

# Mark the current folder in source or target list (using grep --colour)
# This function uses have piped in data
# <command> | mark_currentFilderInList
function mark_currentFilderInList(){
    while read -r line
    do
        echo -n "    "
        grep --colour "${DSF_WORKDIR}" <<< "$line" || echo "$line"
    done
}

# get a list of defined sources
function getSources(){
    grep "^SOURCE=" ${DSF_PROFILES}/*.txt | cut -f 2- -d "=" | sort
}

# get a list of defined targets
function getTargets(){
    cat "${DSF_CONFIG}" | grep "^TARGET=" | cut -f 2- -d "=" | sort
}

# ----------------------------------------------------------------------
# FUNCTIONS SOURCE
# ----------------------------------------------------------------------

function _updateConfig(){
    if [ -z "${DSF_CONFIG}" ]; then
        echo "SKIP: You need to set a profile first"
    else
        local _tmp="${DSF_CONFIG}.tmp"
        (
            echo "#"
            echo "# PROFILE CONFIG - DSF v${DSF_VERSION}"
            echo "#"
            grep "^# CREATED" "${DSF_CONFIG}" || echo "# CREATED     $(date "+%Y-%m-%d %H-%I-%S") " 
            # echo "# LAST UPDATE $(date "+%Y-%m-%d %H-%I-%S") "
            echo "#"
        ) > $_tmp || exit 1

        for mydata in SOURCE DIR FILE TARGET
        do
            grep "^${mydata}=" "${DSF_CONFIG}" | sort -u >> $_tmp
        done
        touch -r "${DSF_CONFIG}" "$_tmp"
        mv "$_tmp" "${DSF_CONFIG}" || exit 1
        echo "INFO: config file was rewritten."
    fi
}

# list all configurations with 
# - source dir
# - files to copy
# - known targets
# if a single source was initialized then only this profile will be shown
function sourcesList(){
    typeset -i i=0
    h2 "LIST PROFILES"
    if ! ls -1 ${DSF_PROFILES}/*.txt >/dev/null 2>&1; then
        echo 
        
        echo No profile was created yet.
        echo 
        exit 1
    fi
    local filelist="${DSF_CONFIG}"
    test -z "$filelist" && filelist="${DSF_PROFILES}/*.txt"

    echo
    for myprofile in $( ls -1 $filelist 2>&1 )
    do
        # echo -n "-----| "
        # ls -ld "$myprofile"
        # echo  "     |"
        # grep 'SOURCE=' "$myprofile" | sed 's#^#     `-- #g' 
        # echo  "           |"
        # grep 'TARGET=' "$myprofile" | sed 's#^#           +-- #g'
        # grep 'TARGET=' "$myprofile" >/dev/null || echo "           INFO: no target yet"
        color cmd
        echo "$myprofile"
        color ok
        grep 'SOURCE=' "$myprofile" | sed 's#^SOURCE=##g' | sort
        color reset
        echo "  |"

        if grep 'DIR=' "$myprofile" >/dev/null; then
            i=$( grep -c 'DIR=' "$myprofile" )
            echo "  +-- dirs ($i):"
            echo "  |     |"
            color ok
            grep 'DIR=' "$myprofile" | sed 's#^DIR=#  |     +-- #g' | sort
            color reset
        else 
            echo "  +-- INFO: no directory was added so far."
        fi
        echo "  |"

        if grep 'FILE='   "$myprofile" >/dev/null; then
            i=$( grep -c 'FILE=' "$myprofile" )
            echo "  +-- files ($i):"
            echo "  |     |"
            color ok
            grep 'FILE='   "$myprofile" | sed 's#^FILE=#  |     +-- #g' | sort
            color reset
        else 
            color warning
            echo "  +-- INFO: no file was added so far."
            color reset
        fi
        echo "  |"

        if grep 'TARGET='   "$myprofile" >/dev/null; then
            i=$( grep -c 'TARGET=' "$myprofile" )
            echo "  +-- targets ($i):"
            echo "        |"
            # color cmd
            grep 'TARGET=' "$myprofile" | sed 's#^TARGET=#        +-- #g' | sort
            # color reset
        else
            color warning
            echo "  +-- WARNING: no target yet"
            color reset
        fi
        echo
    done
}

# set a source directory of software components
# param  string  source directory as absolute or relative path or searchterm to scan in existing sources
function sourceSet(){
    h2 "SET SOURCE"
    DSF_CONFIG=
    DSF_SOURCE=
    DSF_TARGET=
    if [ -z "${1//^\-./}" ]; then
        echo "ERROR: missing param for source."
        exit 1
    fi
    local _sourcedir
    _sourcedir=$( realpath "$1" )

    if ! ls "$1" >/dev/null 2>&1; then
        _sourcedir=$( getSources | grep "$1" | head -1 ) 
        if [ -z "$_sourcedir" ]; then
            echo "ERROR: source not found."
            exit 1
        fi
    fi

    test "$1" != "$_sourcedir" && echo "INFO: transformed [$1] --> [$_sourcedir]"


    DSF_CONFIG=${DSF_PROFILES}/$( echo "$_sourcedir" | md5sum | awk '{ print $1 }' ).txt
    DSF_SOURCE="$_sourcedir"

    if [ ! -f "${DSF_CONFIG}" ]; then
    #     echo "INFO: project already exists: $DSF_SOURCE"
    # else
        showPrompt "Add [$DSF_SOURCE] as new source? Yn >"
        read -r yesno
        if [ -z "$yesno" ] || [ "$yesno" = "y" ] || [ "$yesno" = "Y" ]; then
            echo "INFO: adding new source..."
            echo "SOURCE=$DSF_SOURCE" > "${DSF_CONFIG}"
            _updateConfig
        else
            echo "Doing nothing"
            exit 0
        fi
    fi
    echo "INFO: SOURCE=$DSF_SOURCE was set."

    # detect target with current dir
    mytarget=$( getTargets | grep "$DSF_WORKDIR" | head -1 )
    test -n "$mytarget" && targetSet "$mytarget"
    test -z "$mytarget" && ( echo; echo "INFO: $DSF_WORKDIR was not found in the list of targets.")

}

# ----------------------------------------------------------------------
# FUNCTIONS FILE
# ----------------------------------------------------------------------


# add a file to the selected source
# param  string  sbsolute or relative path (to ${DSF_SOURCE})
function dirAdd(){
    # set -vx
    local _file="${1}"

    h3 "Add dir [$_file]"
    if [ ! -f "${DSF_CONFIG}" ]; then
        echo "ERROR: set a source first"
        exit 1
    fi
    if [ -z "$_file" ]; then
        echo "ERROR: missing param for source file."
        exit 1
    fi

    # a full or any existing file was given ... then make it relative
    if [ ! -d "${DSF_SOURCE}/${_file}" ] && [ -d "$_file" ]; then
        _file=$( realpath "$_file" | sed "s#${DSF_SOURCE}##" )
    fi

    if [ ! -d "${DSF_SOURCE}/${_file}" ]; then
        echo "ERROR: directory must be an existing directory below ${DSF_SOURCE}."
        exit 1
    fi
    _file=${_file//.\/}
    echo "INFO: directory was found [${DSF_SOURCE}/${_file}]"

    if grep "DIR=${_file}$" "${DSF_CONFIG}" >/dev/null; then
        echo "INFO: directory was configured for rollout already."
    else
        showPrompt "Add dir [${_file}] for rollout? Yn >"
        read -r yesno
        if [ -z "$yesno" ] || [ "$yesno" = "y" ] || [ "$yesno" = "Y" ]; then
            echo "INFO: adding new directory"
            echo "DIR=${_file}" >> "${DSF_CONFIG}"
            _updateConfig
        else
            echo "Aborting."
            exit 1
        fi
    fi

}


# add a file to the selected source
# param  string  sbsolute or relative path (to ${DSF_SOURCE})
function fileAdd(){
    # set -vx
    local _file="${1}"

    h3 "Add file [$_file]"
    if [ ! -f "${DSF_CONFIG}" ]; then
        echo "ERROR: set a source first"
        exit 1
    fi
    if [ -z "$_file" ]; then
        echo "ERROR: missing param for source file."
        exit 1
    fi

    # a full or any existing file was given ... then make it relative
    if [ ! -f "${DSF_SOURCE}/${_file}" ] && [ -f "$_file" ]; then
        _file=$( realpath "$_file" | sed "s#${DSF_SOURCE}##" )
    fi

    if [ ! -f "${DSF_SOURCE}/${_file}" ]; then
        echo "ERROR: file must be an existing file below ${DSF_SOURCE}."
        exit 1
    fi
    _file=${_file//.\/}
    echo "INFO: file was found [${DSF_SOURCE}/${_file}]"

    if grep "FILE=${_file}$" "${DSF_CONFIG}" >/dev/null; then
        echo "INFO: file is configured for rollout already."
    else
        showPrompt "Add file [${_file}] for rollout? Yn >"
        read -r yesno
        if [ -z "$yesno" ] || [ "$yesno" = "y" ] || [ "$yesno" = "Y" ]; then
            echo "INFO: adding new file"
            echo "FILE=${_file}" >> "${DSF_CONFIG}"
            _updateConfig
        else
            echo "Aborting."
            exit 1
        fi
    fi
}


# ----------------------------------------------------------------------
# FUNCTIONS TARGET
# ----------------------------------------------------------------------

# set a target 
# param  string   target directory
function targetSet(){
    h2 "SET TARGET $1"
    if [ ! -f "${DSF_CONFIG}" ]; then
        echo "ERROR: set a source first"
        exit 1
    fi
    if [ -z "$1" ]; then
        echo "ERROR: missing param for target."
        exit 1
    fi
    if [ "$1" = "ALL" ]; then
        DSF_TARGET="${1}"
    else
        _targetdir="$1"
        if [ ! -d "$_targetdir" ]; then
            _targetdir=$( getTargets | grep "$1" | head -1 ) 
            if [ -z "$_targetdir" ]; then
                echo "ERROR: target must be an existing directory."
                exit 1
            fi
        fi

        DSF_TARGET=$( realpath "${_targetdir}" | sed "s#/\$##g" ) # remove trailing slash

        test "$1" != "$DSF_TARGET" && echo "INFO: transformed [$1] --> [$DSF_TARGET]"

        if ! grep "TARGET=${DSF_TARGET}$" "${DSF_CONFIG}" >/dev/null; then
        #     echo "INFO: target was configured for rollout already: [${DSF_TARGET}]."
        # else
            showPrompt "Add [$DSF_TARGET] as new target? Yn >"
            read -r yesno
            if [ -z "$yesno" ] || [ "$yesno" = "y" ] || [ "$yesno" = "Y" ]; then
                echo "INFO: adding new target "
                echo "TARGET=${DSF_TARGET}" >> "${DSF_CONFIG}"
                _updateConfig
            else
                echo "Aborting."
                exit 1
            fi
        fi
        
    fi
}

# ----------------------------------------------------------------------
# INTERACTIONS
# ----------------------------------------------------------------------

# enter a source to set
function sourcePrompt(){
        local mysource
        local mytarget
        echo "--- Select a source directory:"
        echo
        echo "- select source as full path from list"
        echo "- enter searchterm to take the first matching item or"
        echo "- enter full path of a new source"
        echo
        getSources | mark_currentFilderInList
        echo
        showPrompt "  source >"
        read -r mysource
        test -z "$mysource" && exit
        sourceSet "$mysource"

        echo
}
# enter a target to set
function targetPrompt(){
        echo "--- Select a target directory:"
        echo "- select target as full path from list or"
        echo "- enter searchterm to take the first matching item or"
        echo "- use keyword ALL to update all targets or"
        echo "- enter full path of a new target"
        echo
        getTargets | mark_currentFilderInList
        echo
        showPrompt "  target >"
        read -r mytarget
        targetSet "$mytarget"
        test -z "$mytarget" && exit
        echo
}
function dirPrompt(){
        echo "--- add a directory:"
        echo
        echo "- enter relative dir below $DSF_SOURCE (or as absolute path)"
        echo "- enter . do sync complete $DSF_SOURCE to targets"
        echo
        cd "$DSF_SOURCE" && find . -type d | grep -vE "/(.git|.svn)/*" | sort | head -20 | sed "s#^#    #" && cd - >/dev/null
        echo
        showPrompt "  add dir >"
        read -r mydir
        test -z "$mydir" && exit
        dirAdd "$mydir"
        echo
}
function filePrompt(){
        echo "--- add a file:"
        echo
        echo "- enter reletive filenam below $DSF_SOURCE (or as absolute path)"
        echo
        cd "$DSF_SOURCE" && find . -type f | sort | head -20 | sed "s#^#    #" && cd - >/dev/null
        echo
        showPrompt "  add file >"
        read -r myfile
        test -z "$myfile" && exit
        fileAdd "$myfile"
        echo
}

# ----------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------

function showHelp(){
    local _src="/home/axel/deployfiles/docs"
    local _tgt="/home/projects/project_A"
echo "
Copy sourcefiles to one or many targets.
It can be used to handle repository files of low level components or basic
files and update them in multiple projects.


SYNTAX:
$_self [OPTIONS] [FROM] [TO]

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
    -S          set a source in interactive mode
    -t [TO]     set a target for a given source
                You need to set a source (see -s) before -t
    -u          update ALL known targets; [TO] is not required - targets will
                be read from config
                You need to set a source (see -s) before -u
    -w          where is .. something for the current directory?
                Search current directory for definitions in sources or targets
    -W          Like -w but it shows diffs

All projects are written as txt file wit md5 hash into \"profiles\" directory.
    $DSF_PROFILES
To delete a file or target grep for it in the profiles dir.

EXAMPLES:

Create/ set a source.
The target inside the current durectory will be detected and then the files
will be copied to the target.

    $_self -S
                Set a source interactively and update files in autodetected 
                target.

    $_self -s $_src
                Set a given source source. If it does not exist yet than a new
                profile will be created interactively.

Add source files and directories
    $_self -s $_src -d abc
                -d = add directory
                Add a directory to the project. You get a prompt to add it if it 
                does not exist yet.

    $_self -s $_src -f style.css
                -f = add file
                Add a file to the project. You get a prompt to add it if it 
                does not exist yet.

    Hint: You can repeat -d and -f multiple times.

Create/ set target
    $_self -s $_src -t $_tgt
    OR
    $_self $_src $_tgt
                -t = target
                Add a targetdir to the project. You get a prompt to add it if 
                it does not exist yet.
                Then it copies all known files to the target.

Update
    $_self -s $_src -u
                -u = update all
                Copy all known files to all known targets.

More:
    $_self -i   Interactive mode to select from known sources and targets.

    $_self -l   list all known projects and show details

    $_self -s $_src -l
                -l = list
                list details of selected project

    $_self -w   where is ... search: something for the current directory
"
}

# ----------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------

_self=$( basename $0 )
color cmd
echo -e "_______________________________________________________________________________

 ▄▄▄▄    ▄▄▄▄  ▄▄▄▄▄   |
 █   ▀▄ █▀   ▀ █       |  DEPLOY
 █    █ ▀█▄▄▄  █▄▄▄▄   |    SOURCE                                       v${DSF_VERSION}
 █    █     ▀█ █       |      FILES  ..  to multiple local targets
 █▄▄▄▀  ▀▄▄▄█▀ █       |
 
Axel Hahns helper tool to update local files in other projects.
_______________________________________________________________________________
"
color reset

test -d "${DSF_PROFILES}" || mkdir -p "${DSF_PROFILES}"

while getopts ":h :c :e :i :l :u :d: :f: :s: :S :t: :w :W" OPT; do
  if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"       # extract long option name
    OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`

  fi
  # echo "OPT = [$OPT]; OPTARG = [$OPTARG]"

  case "$OPT" in
    # ----- HELP
    h) showHelp; exit 0; ;;

    # ----- REAL ACTIONS
    c) DSF_ACTION="compare";;
    e) DSF_ACTION="edit";;
    i) DSF_ACTION="menu";;

    l) sourcesList; exit 0;;
    d) dirAdd "${OPTARG}"; DSF_ACTION= ;;
    f) fileAdd "${OPTARG}"; DSF_ACTION= ;;
    s) sourceSet "${OPTARG}"; DSF_ACTION=copy ;;
    S) sourcePrompt; DSF_ACTION=copy ;;
    t) targetSet "${OPTARG}"; DSF_ACTION=copy ;;
    u) DSF_ACTION="updateall" ;;
    w) DSF_ACTION="whereis"; doDiff=;;
    W) DSF_ACTION="whereis"; doDiff=1;;
  esac
done

shift $((OPTIND - 1))

# --- options handling is done...

test $OPTIND -eq 1 && echo "HINT: Use the parameter -h to get the help page."

#echo "DEBUG: $# params left: $*"

if [ $# -ge 1 ]; then
    sourceSet "${1}"
    shift 1
    if [ $# -ge 1 ]; then
        targetSet "${1}"
        DSF_ACTION=copy
    fi
fi

# ----------------------------------------------------------------------

case "$DSF_ACTION" in
    menu)
        test -z "$DSF_SOURCE" && sourcePrompt
        while true;do
            h2 "D.S.F v${DSF_VERSION} :: Menu"
            echo 
            echo "ressources:"
            echo "  $( key "s" ) - select source    $DSF_SOURCE"
            echo "  $( key "t" ) - select target    $DSF_TARGET"
            echo
            echo "  $( key "d" ) - add a dir"
            echo "  $( key "f" ) - add a file"
            # echo "  f - add a file"
            # echo "  d - add a dir"
            echo
            echo "actions:"
            echo "  $( key "l" ) - list configuration"
            echo "  $( key "e" ) - edit configuration"
            echo "  $( key "c" ) - compare source and target"
            echo "  $( key "u" ) - update selected target(s)"
            echo
            showPrompt "selection >"
            read -r selected

            case "$selected" in
                s) sourcePrompt ;;
                t) targetPrompt ;;

                d) dirPrompt ;;
                f) filePrompt ;;

                l) sourcesList ;;
                e) _editconfig ;;

                c) _diff ;;
                u) _copy ;;

                *) echo "TODO";;
            esac
        done
        ;;
    compare) _diff ;;
    copy) _copy ;;
    edit) _editconfig ;;
    updateall) _copytoalltargets ;;
    whereis) _whereis $doDiff ;;

    *)
        echo
esac

# ----------------------------------------------------------------------
