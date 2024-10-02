#! /bin/bash
# Copyright (c) 2024 iQbis consulting GmbH

set -u
readonly SUBCOMMAND_NAME="branch-select"
readonly -a FZFARGS=( --height=20% --reverse --info=inline )

CHECKCMD() {
    type "$1" >/dev/null 2>&1
}

USAGE() {
    echo "USAGE: git $SUBCOMMAND_NAME [OPTIONs] [--] [BRANCH_NAME_PATTERN]"
    echo "Select and checkout branches interactively."
    echo ""
    echo "NOTE: This script requires \`fzf\`."
    echo ""
    echo " Option              | Description                                        "
    echo "---------------------|----------------------------------------------------"
    echo " -h --help           | Show this help.                                    "
    echo " -d --detach         | Detach HEAD at named commit.                       "
    echo " -w --worktrees      | Enable worktree switching. (Opens in a subshell.)  "
    echo " -W --only-worktrees | Only switch to any worktree.                       "
    echo "    --dry-run        | Don't checkout anything. Just print the commands.  "
    echo "    --debug          | Log debugging infomation.                          "
    echo ""
    echo "All positional arguments are joined by \"*\" into the BRANCH_NAME_PATTERN which is then passed to \`git branch\` to pre-filter the list."
    echo ""
}

declare -i DODETACH="0"
declare -i DOWORKTREES="0"
declare -i DODRYRUN="0"
declare -i DODEBUG="0"

getoptstr="$(getopt -n "$0" -o "hdwW" -l "help,detach,worktrees,only-worktrees,dry-run,debug" -- "$@")" || exit "$?"
eval set -- "$getoptstr"
unset getoptstr
while test "$#" -gt 0 ;do
    case "$1" in
        "-h"|"--help") USAGE ;exit 0 ;;
        "-d"|"--detach") DODETACH="1" ;;
        "-w"|"--worktrees") DOWORKTREES="1" ;;
        "-W"|"--only-worktrees") DOWORKTREES="2" ;;
        "--dry-run") DODRYRUN="1" ;;
        "--debug") DODEBUG="1" ;;
        "--") shift ;break ;;
        *) { echo -n "Unhandled argument at:" ;printf ' "%s"' "$@" ;echo ; } >&2 ;exit 1 ;;
    esac
    shift
done
IFS="*"
PATTERN="*$**"
unset IFS

if ! CHECKCMD fzf ;then
    echo "Could not find the \`fzf\` command. Please install \`fzf\` to use this script." >&2
    if test -f /etc/os-release -a -r /etc/os-release ;then
        case "$(sed -ne 's/^NAME="\(.*\)"$/\1/p' /etc/os-release)" in
            "Ubuntu"|*"Debian"*) echo "You may install \`fzf\` from the package repositories using \`sudo apt install fzf\`." >&2 ;exit 1 ;;
        esac
    fi
    echo "The project page https://github.com/junegunn/fzf lists installation methods." >&2
    exit 1
fi

LOGDEBUG() {
    if test "$DODEBUG" -ne 0 ;then
        echo "$*" >&2
    fi
}

RUNCMD() {
    local arg
    for arg in "$@" ;do
        if [[ "$arg" == '' || "$arg" == *' '* || "$arg" == *'!'* ]] ;then
            echo -n "\"$arg\" " >&2
        else
            echo -n "$arg " >&2
        fi
    done
    echo >&2
    if test "$DODRYRUN" -eq 0 ;then
        "$@" || exit "$?"
    fi
}

GITCANSWITCH() {
    git switch >/dev/null 2>&1
    test "$?" -eq 128
}

GITCHECKOUTDETACH() {
    if GITCANSWITCH ;then
        RUNCMD git switch --detach "$@"
    else
        RUNCMD git checkout --detach "$@"
    fi
}

GITCHECKOUTBRANCH() {
    if GITCANSWITCH ;then
        RUNCMD git switch "$@"
    else
        RUNCMD git checkout "$@"
    fi
}

GITCHECKOUTBRANCHNEW() {
    if GITCANSWITCH ;then
        RUNCMD git switch --create "$@"
    else
        RUNCMD git checkout -b "$@"
    fi
}

GITWORKTREE_OPEN() {
    if test "$DOWORKTREES" -eq 0 ;then
        return 0
    fi
    WORKTREEPATH="$(git worktree list --porcelain |grep -FxB2 "branch refs/heads/$BRANCH" |sed -ne 's/^worktree \(.*\)$/\1/p')"
    if test -z "$WORKTREEPATH" ;then
        LOGDEBUG "no worktree on \"refs/heads/$BRANCH\""
    else
        LOGDEBUG "worktree at \"$WORKTREEPATH\" on \"refs/heads/$BRANCH\""
        echo "Opening worktree: $WORKTREEPATH"
        cd "$WORKTREEPATH" || exit "$?"
    fi
}

GITWORKTREE_EXEC() {
    if test "$DOWORKTREES" -eq 0 ;then
        exit
    fi
    if test -n "$WORKTREEPATH" ;then
        echo -n "Now on worktree: "
        pwd
        exec $SHELL
    fi
    exit
}

WORKTREEPATH=""
LOGDEBUG "PATTERN=\"$PATTERN\""
if test "$DOWORKTREES" -eq 2 ;then
    PATTERN="${PATTERN//"*"/".*"}"
    LOGDEBUG "PATTERN=\"$PATTERN\""
    WORKTREEPATH="$(git worktree list |grep "${PATTERN//"."/".*"}" |fzf "${FZFARGS[@]}")"
    LOGDEBUG "SELECTED=\"$WORKTREEPATH\""
    if test -z "$WORKTREEPATH" ;then
        echo "No option selected." >&2
        exit 1
    elif [[ "$WORKTREEPATH" =~ ^(.*[^ ])" "*"   "[A-Fa-f0-9]+" "("(".*")"|"[".*"]")$ ]] ;then
        WORKTREEPATH="${BASH_REMATCH[1]}"
        LOGDEBUG "WORKTREEPATH=\"$WORKTREEPATH\""
        cd "$WORKTREEPATH" || exit "$?"
    else
        echo "An internal error occurred: Unable to determine worktree path for selection \"$WORKTREEPATH\"." >&2
        exit 1
    fi
    GITWORKTREE_EXEC
fi
git status |head -n1
FILTER=" "
if test "$DODETACH" -ne 0 ;then
    FILTER+="*+"
elif test "$DOWORKTREES" -ne 0 ;then
    FILTER+="+"
fi
LOGDEBUG "FILTER=\"$FILTER\""
BRANCH="$(git branch --all --sort=-committerdate --list "$PATTERN" |grep "^[$FILTER] [^(]" |fzf "${FZFARGS[@]}")"
if test -z "$BRANCH" ;then
    echo "No option selected." >&2
    exit 1
fi
BRANCH="${BRANCH#[*+ ] }"
BRANCH="${BRANCH% -> *}"
LOGDEBUG "BRANCH=\"$BRANCH\""
if [[ "$BRANCH" == *"/"* ]] ;then
    REF="refs/$BRANCH"
else
    REF="refs/heads/$BRANCH"
fi
LOGDEBUG "REF=\"$REF\""
REF="$(git for-each-ref --format '%(if)%(symref)%(then)%(symref)%(else)%(refname)%(end)' "$REF")"
LOGDEBUG "REF=\"$REF\""
if [[ "$REF" =~ ^"refs/remotes/"([^/]*)"/merge-requests/"([^/]*)$ ]] ;then
    REMOTE="${BASH_REMATCH[1]}"
    if test "$DODETACH" -ne 0 ;then
        GITCHECKOUTDETACH "$REF"
        exit
    fi
    BRANCH="$(git for-each-ref --format '%(refname)' --points-at "$REF" "refs/remotes/$REMOTE/*")"
    if test -z "$BRANCH" ;then
        GITCHECKOUTDETACH "$REF"
        exit
    else
        REF="$BRANCH"
        LOGDEBUG "REF=\"$REF\""
    fi
fi
if [[ "$REF" =~ ^"refs/remotes/"([^/]*)"/"([^/]*)$ ]] ;then
    BRANCH="${BASH_REMATCH[2]}"
    GITWORKTREE_OPEN
    if test "$DODETACH" -ne 0 ;then
        GITCHECKOUTDETACH "$REF"
    elif git show-ref --verify --quiet "refs/heads/$BRANCH" ;then
        GITCHECKOUTBRANCH "$BRANCH"
    else
        GITCHECKOUTBRANCHNEW "$BRANCH" "$REF"
    fi
    GITWORKTREE_EXEC
fi
if [[ "$REF" =~ ^"refs/heads/"([^/]*)$ ]] ;then
    BRANCH="${BASH_REMATCH[1]}"
    GITWORKTREE_OPEN
    if test "$DODETACH" -ne 0 ;then
        GITCHECKOUTDETACH "$BRANCH"
    else
        GITCHECKOUTBRANCH "$BRANCH"
    fi
    GITWORKTREE_EXEC
fi

echo "No known checkout method for ref \"$REF\"." >&2
exit 1

