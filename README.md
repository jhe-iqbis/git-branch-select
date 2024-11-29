# git-branch-select

Select and checkout branches interactively.

Don't want to type long branch names? Can't remember the exact start of a branch name so TAB completion doesn't work? Need to checkout merge requests and resolve merge conflicts with `main`?

No Problem! Use `git-branch-select`! ;)

(Works with git worktrees as well.)

## Installation

Link the script into your PATH.

To install it for your current user:

```sh
mkdir -pv ~/bin
ln -s "$(realpath git-branch-select.sh)" ~/bin/git-branch-select
exec $SHELL
```

To install it for all users on your system:

```sh
sudo ln -s "$(realpath git-branch-select.sh)" /usr/local/bin
```

You can then run the script using:

```sh
git-branch-select --help
# or
git branch-select --help
```

You may also want to alias the command:

```sh
git config --global alias.bs branch-select
```

You can then use:

```sh
git bs --help
```

(Note that you can alias `branch-select --worktrees` as well, if you want to have worktree switchting always enabled.)

## Features

`git-branch-select` handles local and remote branches, merge request refs from the remote and worktrees.

- Selecting a local branch will check it out.
- Selecting a remote branch will create a local branch tracking the remote branch and check it out.
- Selecting the remote HEAD will do the same as selecting the remote default branch directly.
- Selecting a merge request ref will do the same as selecting the corresponding remote branch directly.
- When using the `-d/--detach` option, you can select any ref and it will be checked out detached.
- When using the `-w/--worktrees` option, selecting a branch where the local branch is checked out in another worktree, will start a subshell in that worktree.
- When using the `-W/--only-worktrees` option, you can only select a worktree to start the subshell in.

## Examples

```sh
$ git bs
On branch main
>   < 45/45
>   remotes/origin/git-tools
    remotes/origin/merge-requests/16
    remotes/origin/some-other-feature
    remotes/origin/merge-requests/15
    remotes/origin/main
    remotes/origin/HEAD -> origin/main
git switch --create git-tools refs/remotes/origin/git-tools
Branch 'git-tools' set up to track remote branch 'git-tools' from 'origin'.
Switched to a new branch 'git-tools'
$ git bs
On branch git-tools
> main  < 7/46
>   main
    remotes/origin/main
    remotes/origin/HEAD -> origin/main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git worktree add ../git-tools
Preparing worktree (checking out 'git-tools')
HEAD is now at ...
$ git bs -W
>   < 4/4
> /home/user/repo        ... [main]
  /home/user/git-tools   ... [git-tools]
```

## Additional Tools

There are some additional tools bundled with `git-branch-select` that you can install the same way. Here is a short list:

| Tool                     | Description                                                                       |
| ------------------------ | --------------------------------------------------------------------------------- |
| `git-branch-auto-delete` | Delete local branches, that were merged and deleted on the remote.                |
| `git-branch-show-commit` | Show the HEAD commit of each branch.                                              |
| `git-diff-merge`         | Verify the changes introduced by a conflict resolution merge on a feature branch. |
