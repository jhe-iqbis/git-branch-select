#! /bin/bash
# Copyright (c) 2024 iQbis consulting GmbH

set -u

git branch |sed -nE 's/^. ([^(].*)$/\1/p' |xargs -rd'\n' git show --no-patch

