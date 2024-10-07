#! /bin/bash
# Copyright (c) 2024 iQbis consulting GmbH

set -u

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

