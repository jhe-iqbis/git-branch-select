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
readonly SUBCOMMAND_NAME="diff-merge"

USAGE() {
    echo "USAGE: git $SUBCOMMAND_NAME [OPTIONs] [--] [MERGE_COMMIT]"
    echo "Diff changes between two branches before and after a merge."
    echo ""
    echo "If no MERGE_COMMIT is given, assume HEAD."
    echo ""
    echo " Option                    | Description                                         "
    echo "---------------------------|-----------------------------------------------------"
    echo " -h --help                 | Show this help.                                     "
    echo " -s --self-parent NUM      | The parent number to use for the self/right side.   "
    echo " -o --other-parent NUM     | The parent number to use for the other/left side.   "
    echo " -l --left-parent NUM      | The parent number to use for the other/left side.   "
    echo " -r --right-parent NUM     | The parent number to use for the self/right side.   "
    echo "    --color DIFF_COLOR     | Color argument value to \`diff\`. Defaults to \"auto\". "
    echo " -v --verbose              | Display commits to be diffed.                       "
    echo ""
}

declare -i SELFPARENT="0"
declare -i OTHERPARENT="0"
declare -i VERBOSE="0"
DIFFCOLOR="auto"
COMMIT="HEAD"

getoptstr="$(getopt -n "$0" -o "hs:o:l:r:v" -l "help,self-parent:,other-parent:,left-parent:,right-parent:,color:,verbose" -- "$@")" || exit "$?"
eval set -- "$getoptstr"
unset getoptstr
while test "$#" -gt 0 ;do
    case "$1" in
        "-h"|"--help") USAGE ;exit 0 ;;
        "-s"|"--self-parent"|"-r"|"--right-parent") shift ;SELFPARENT="$1" ;;
        "-o"|"--other-parent"|"-l"|"--left-parent") shift ;OTHERPARENT="$1" ;;
        "--color") shift ;DIFFCOLOR="$1" ;;
        "-v"|"--verbose") VERBOSE="1" ;;
        "--") shift ;break ;;
        *) { echo -n "Unhandled argument at:" ;printf ' "%s"' "$@" ;echo ; } >&2 ;exit 1 ;;
    esac
    shift
done
if test "$#" -gt 0 ;then
    COMMIT="$1"
    shift
fi
if test "$#" -gt 0 ;then
    echo "Too many positional arguments: $*" >&2
    exit 1
fi

case "$(git rev-parse "$COMMIT^@" |wc -l)" in
    0) echo "The given MERGE_COMMIT \"$COMMIT\" has no parents." >&2 ;exit 1 ;;
    1) echo "The given MERGE_COMMIT \"$COMMIT\" is not a merge." >&2 ;exit 1 ;;
    2) ;;
    3) test "$SELFPARENT" -le 0 -a "$OTHERPARENT" -le 0 && echo "The given MERGE_COMMIT \"$COMMIT\" has more than two parents. Only diffing the first two. Give at least one parent explicitly to suppress this warning." >&2 ;;
esac

test "$SELFPARENT" -le 0 && SELFPARENT="1"
test "$OTHERPARENT" -le 0 && OTHERPARENT="2"
readonly COMMIT_LL="$(git rev-parse "$COMMIT^$OTHERPARENT")"
readonly COMMIT_LR="$(git rev-parse "$COMMIT^$SELFPARENT")"
readonly COMMIT_RL="$(git rev-parse "$COMMIT^$OTHERPARENT")"
readonly COMMIT_RR="$(git rev-parse "$COMMIT")"

if test "$VERBOSE" -ge 1 ;then
    git log --boundary --graph "$COMMIT" --not "$COMMIT^@"
fi
echo "left  diff $COMMIT_LL...$COMMIT_LR"
echo "right diff $COMMIT_RL..$COMMIT_RR"
diff --color="$DIFFCOLOR" \
    <(git diff "$COMMIT_LL...$COMMIT_LR" |grep '^[+-]') \
    <(git diff "$COMMIT_RL..$COMMIT_RR" |grep '^[+-]')

