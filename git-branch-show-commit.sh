#! /bin/bash
# MIT License
#
# Copyright (c) 2024 iQbis consulting GmbH
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


set -u
readonly SUBCOMMAND_NAME="branch-show-commit"

USAGE() {
    echo "USAGE: git $SUBCOMMAND_NAME [OPTIONs] [--] [BRANCH_NAME] [GIT_SHOW_ARGs]"
    echo "Show the last commit of each branch."
    echo ""
    echo " Option                    | Description                                        "
    echo "---------------------------|----------------------------------------------------"
    echo " -h --help                 | Show this help.                                    "
    echo " -a --all                  | list both remote-tracking and local branches       "
    echo " -r --remotes              | list only remote-tracking branches                 "
    echo " -l --local                | list only local branches                           "
    echo " -s --sort                 | field name to sort branches on                     "
    echo " -S --no-sort              | don't sort branches                                "
    echo "    --contains <COMMIT>    | print only branches that contain the commit        "
    echo "    --no-contains <COMMIT> | print only branches that don't contain the commit  "
    echo "    --merged <COMMIT>      | print only branches that are merged                "
    echo "    --no-merged <COMMIT>   | print only branches that are not merged            "
    echo " -p -u --patch             | show diff for commits                              "
    echo " -s --no-patch             | suppress diff output for commits                   "
    echo " -q --quiet                | suppress diff output for commits                   "
    echo " -f --from <COMMIT>        | print log from the commit to its containing branch "
    echo ""
}

declare -a GITBRANCHARGS=()
declare -a GITSHOWARGS=()
GITBRANCHTYPE=""
GITBRANCHSORT="-committerdate"
GITSHOWPATCH="--no-patch"
GITBRANCHNAME=""

getoptstr="$(getopt -n "$0" -o "harls:Spuqf:" -l "help,all,remotes,local,sort:,no-sort,contains:,no-contains:,merged:,no-merged:,patch,no-patch,quiet,from:" -- "$@")" || exit "$?"
eval set -- "$getoptstr"
unset getoptstr
while test "$#" -gt 0 ;do
    case "$1" in
        "-h"|"--help") USAGE ;exit 0 ;;
        "-a"|"--all"|"-r"|"--remotes") GITBRANCHTYPE="$1" ;;
        "-l"|"--local") GITBRANCHTYPE="" ;;
        "-s"|"--sort") shift ;GITBRANCHSORT="$1" ;;
        "-S"|"--no-sort") GITBRANCHSORT="" ;;
        "--contains"|"--no-contains"|"--merged"|"--no-merged") GITBRANCHARGS+=( "$1" "$2" ) ;shift ;;
        "-p"|"-u"|"--patch"|"--no-patch"|"-q"|"--quiet") GITSHOWPATCH="$1" ;;
        "-f"|"--from") shift ;GITBRANCHARGS+=( "--contains" "$1" ) ;GITSHOWARGS+=( "^$1~" ) ;;
        "--") shift ;break ;;
        *) { echo -n "Unhandled argument at:" ;printf ' "%s"' "$@" ;echo ; } >&2 ;exit 1 ;;
    esac
    shift
done
if test "$#" -gt 0 ;then
    GITBRANCHNAME="$1"
    shift
fi
GITSHOWARGS+=( "$@" )

if test -n "$GITBRANCHTYPE" ;then
    GITBRANCHARGS+=( "$GITBRANCHTYPE" )
fi
if test -n "$GITBRANCHSORT" ;then
    GITBRANCHARGS+=( "--sort" "$GITBRANCHSORT" )
fi
if test -n "$GITBRANCHNAME" ;then
    GITBRANCHARGS+=( "--" "$GITBRANCHNAME" )
fi

git branch --list --format='%(refname)' "${GITBRANCHARGS[@]}" |xargs -rd'\n' git show "${GITSHOWPATCH}" "${GITSHOWARGS[@]}"

