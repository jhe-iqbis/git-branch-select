#! /bin/bash
# MIT License
#
# Copyright (c) 2025 iQbis consulting GmbH
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
    echo " Option                    | Description                                           "
    echo "---------------------------|-------------------------------------------------------"
    echo " -h --help                 | Show this help.                                       "
    echo " -s --self-parent NUM      | The parent number to use for the self/right side.     "
    echo " -o --other-parent NUM     | The parent number to use for the other/left side.     "
    echo " -l --left-parent NUM      | The parent number to use for the other/left side.     "
    echo " -r --right-parent NUM     | The parent number to use for the self/right side.     "
    echo "    --color DIFF_COLOR     | Color argument value to \`diff\`. Defaults to \"auto\".   "
    echo "    --use-revs             | Diff using revision selectors. (This is the default.) "
    echo "    --use-hashes           | Resolve revisions into commit hashes before diffing.  "
    echo " -v --verbose              | Display commits to be diffed. (Implies --use-hashes.) "
    echo ""
}

declare -i PARENT_L="0"
declare -i PARENT_R="0"
declare -i USEHASHES="0"
declare -i VERBOSE="0"
DIFFCOLOR="auto"
COMMIT="HEAD"

getoptstr="$(getopt -n "$0" -o "hs:o:l:r:v" -l "help,self-parent:,other-parent:,left-parent:,right-parent:,color:,use-revs,use-hashes,verbose" -- "$@")" || exit
eval set -- "$getoptstr"
unset getoptstr
while test "$#" -gt 0 ;do
    case "$1" in
        "-h"|"--help") USAGE ;exit 0 ;;
        "-o"|"--other-parent"|"-l"|"--left-parent") shift ;PARENT_L="$1" ;;
        "-s"|"--self-parent"|"-r"|"--right-parent") shift ;PARENT_R="$1" ;;
        "--color") shift ;DIFFCOLOR="$1" ;;
        "--use-revs") USEHASHES="0" ;;
        "--use-hashes") USEHASHES="1" ;;
        "-v"|"--verbose") VERBOSE="1" ;USEHASHES="1" ;;
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
    *) test "$PARENT_L" -le 0 -a "$PARENT_R" -le 0 && echo "The given MERGE_COMMIT \"$COMMIT\" has more than two parents. Only diffing the first two. Give at least one parent explicitly to suppress this warning." >&2 ;;
esac

test "$PARENT_L" -le 0 && PARENT_L="2"
test "$PARENT_R" -le 0 && PARENT_R="1"
COMMIT_LL="$COMMIT^$PARENT_L"
COMMIT_LR="$COMMIT^$PARENT_R"
COMMIT_RL="$COMMIT^$PARENT_L"
COMMIT_RR="$COMMIT"

if test "$USEHASHES" -ge 1 ;then
    COMMIT_LL="$(git rev-parse "$COMMIT_LL")"
    COMMIT_LR="$(git rev-parse "$COMMIT_LR")"
    COMMIT_RL="$(git rev-parse "$COMMIT_RL")"
    COMMIT_RR="$(git rev-parse "$COMMIT_RR")"
fi
if test "$VERBOSE" -ge 1 ;then
    git log --boundary --graph "$COMMIT" --not "$COMMIT^@"
fi
echo "left  diff $COMMIT_LL...$COMMIT_LR"
echo "right diff $COMMIT_RL..$COMMIT_RR"
diff --color="$DIFFCOLOR" \
    <(git diff "$COMMIT_LL...$COMMIT_LR" |grep '^[+-]') \
    <(git diff "$COMMIT_RL..$COMMIT_RR" |grep '^[+-]')

