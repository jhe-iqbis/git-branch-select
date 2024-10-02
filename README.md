# git-branch-select

Select and checkout branches interactively.

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
