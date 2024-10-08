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
readonly SUBCOMMAND_NAME="branch-auto-delete"

USAGE() {
    echo "USAGE: git $SUBCOMMAND_NAME"
    echo "Delete merged local branches."
    echo ""
}

if test "$#" -gt 0 ;then
    USAGE
    exit 1
fi

git branch |grep '^  ' | \
while read -r BRANCH_NAME ;do
    BRANCH_REF="refs/heads/$BRANCH_NAME"
    echo -n "$BRANCH_NAME"
    REMOTE="$(git config "branch.$BRANCH_NAME.remote")"
    if test -z "$REMOTE" ;then
        echo " does not track a remote."
        continue
    fi
    REMOTE_BRANCH_REF="refs/remotes/$REMOTE/$BRANCH_NAME"
    REMOTE_BRANCH_NAME="$REMOTE/$BRANCH_NAME"
    if git show-ref --verify --quiet "$REMOTE_BRANCH_REF" ;then
        echo " tracks existing $REMOTE_BRANCH_NAME."
        continue
    fi
    REMOTE_HEAD_REF="refs/remotes/$REMOTE/HEAD"
    REMOTE_HEAD_NAME="$REMOTE/HEAD"
    if ! git merge-base --is-ancestor "$BRANCH_REF" "$REMOTE_HEAD_REF" ;then
        echo " tracks missing $REMOTE_BRANCH_NAME but is not merged into $REMOTE_HEAD_NAME."
        continue
    fi
    echo -n " tracks merged and deleted $REMOTE_BRANCH_NAME: "
    git branch --delete "$BRANCH_NAME"
done

