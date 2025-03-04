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
readonly SUBCOMMAND_NAME="diff-changes"

USAGE() {
    echo "USAGE: git $SUBCOMMAND_NAME [OPTIONs] [--] RIGHT_COMMIT_OR_RANGE"
    echo "       git $SUBCOMMAND_NAME [OPTIONs] [--] LEFT_COMMIT_OR_RANGE RIGHT_COMMIT_OR_RANGE"
    echo "Diff changes introduced by two commits or ranges of commits."
    echo ""
    echo "If LEFT_COMMIT_OR_RANGE is not given, the HEAD commit is used for the left side."
    echo ""
    echo " Option                    | Description                                           "
    echo "---------------------------|-------------------------------------------------------"
    echo " -h --help                 | Show this help.                                       "
    echo " -l --left-parent NUM      | The parent number to use for the left side.           "
    echo " -r --right-parent NUM     | The parent number to use for the right side.          "
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
COMMIT_L="HEAD"

getoptstr="$(getopt -n "$0" -o "hl:r:v" -l "help,left-parent:,right-parent:,color:,use-revs,use-hashes,verbose" -- "$@")" || exit
eval set -- "$getoptstr"
unset getoptstr
while test "$#" -gt 0 ;do
    case "$1" in
        "-h"|"--help") USAGE ;exit 0 ;;
        "-l"|"--left-parent") shift ;PARENT_L="$1" ;;
        "-r"|"--right-parent") shift ;PARENT_R="$1" ;;
        "--color") shift ;DIFFCOLOR="$1" ;;
        "--use-revs") USEHASHES="0" ;;
        "--use-hashes") USEHASHES="1" ;;
        "-v"|"--verbose") VERBOSE="1" ;USEHASHES="1" ;;
        "--") shift ;break ;;
        *) { echo -n "Unhandled argument at:" ;printf ' "%s"' "$@" ;echo ; } >&2 ;exit 1 ;;
    esac
    shift
done
case "$#" in
    0) echo "Missing positional argument."
        echo "USAGE: git $SUBCOMMAND_NAME [OPTIONs] [--] RIGHT_COMMIT_OR_RANGE"
        echo "       git $SUBCOMMAND_NAME [OPTIONs] [--] LEFT_COMMIT_OR_RANGE RIGHT_COMMIT_OR_RANGE"
        exit 1 ;;
    1) COMMIT_R="$1" ;;
    2) COMMIT_L="$1" ;COMMIT_R="$2" ;;
    *) echo "Too many positional arguments: $*" >&2 ;exit 1 ;;
esac

SET_COMMITS() {
    local name="$1"
    shift
    local value="$1"
    shift
    local parent="$1"
    shift
    local result_var="$1"
    shift
    local left right
    case "$value" in
        *"..."*) right="${value##*...}" ;left="$(git merge-base "${value%...*}" "$right")" || exit "$?" ;;
        *".."*) left="${value%..*}" ;right="${value##*..}" ;;
        *)
            case "$(git rev-parse "$value^@" |wc -l)" in
                0) echo "The given $name \"$value\" has no parents." >&2 ;exit 1 ;;
                1) ;;
                *) test "$parent" -le 0 && echo "The given $name \"$value\" has more than one parent. Only diffing the first. Give the parent explicitly to suppress this warning." >&2 ;;
            esac
            test "$parent" -le 0 && parent="1"
            left="$value^$parent"
            right="$value" ;;
    esac
    declare -g "${result_var}L=$left" "${result_var}R=$right"
}

SET_COMMITS LEFT_COMMIT "$COMMIT_L" "$PARENT_L" COMMIT_L
SET_COMMITS RIGHT_COMMIT "$COMMIT_R" "$PARENT_R" COMMIT_R

if test "$USEHASHES" -ge 1 ;then
    COMMIT_LL="$(git rev-parse "$COMMIT_LL")"
    COMMIT_LR="$(git rev-parse "$COMMIT_LR")"
    COMMIT_RL="$(git rev-parse "$COMMIT_RL")"
    COMMIT_RR="$(git rev-parse "$COMMIT_RR")"
fi
if test "$VERBOSE" -ge 1 ;then
    git log --boundary --graph "$COMMIT_LR" "$COMMIT_RR" --not "$COMMIT_LL" "$COMMIT_RL"
fi
echo "left  diff $COMMIT_LL $COMMIT_LR"
echo "right diff $COMMIT_RL $COMMIT_RR"
diff --color="$DIFFCOLOR" \
    <(git diff "$COMMIT_LL" "$COMMIT_LR" |grep '^[+-]') \
    <(git diff "$COMMIT_RL" "$COMMIT_RR" |grep '^[+-]')

