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
readonly SUBCOMMAND_NAME="get-version"

USAGE() {
    echo "USAGE: git $SUBCOMMAND_NAME [OPTIONs] [--] [(COMMIT-ISH|TICKET_NUMBER)s]"
    echo "Print version information for commits (e.g. for a ticket)."
    echo ""
    echo "If the automatic distinction between COMMIT-ISHs and TICKET_NUMBERs does not work, these can also be given by -c/--commit and -t/--ticket. However, the order of the output may not match the order of the arguments if different variants are used to specify commits and ticket numbers."
    echo ""
    echo " Option                               | Description                                                                                          "
    echo "--------------------------------------|------------------------------------------------------------------------------------------------------"
    echo " -h --help                            | Show this help.                                                                                      "
    echo " -c --commit COMMIT-ISH               | Show information for this commit.                                                                    "
    echo " -A --ancestor -m --merged COMMIT-ISH | Restrict the search for commits by passing COMMIT-ISH to \`git log\`.                                  "
    echo " -a --all                             | Pass \"--all\" to \`git log\` to search for commits.                                                   "
    echo " -b --branches                        | Pass \"--branches\" to \`git log\` to search for commits.                                              "
    echo " -s --search TEXT                     | Search for commits with the given TEXT. (See \"--grep=\" in \`git log --help\`.)                         "
    echo " -t --ticket TICKET_NUMBER            | Search for commits with the given TICKET_NUMBER. (Like \"--search #TICKET_NUMBER\".)                   "
    echo " -x --arg --argument GIT_LOG_ARG      | Restrict the search for commits by passing GIT_LOG_ARG to \`git log\`.                                 "
    echo " -V --version-format PRINTF_FMT       | Version format for \`printf\` before replacing \"%version\".                                             "
    echo " -f --fmt --format OUTPUT_FMT         | Output format. See \"OUTPUT_FMT\" below.                                                               "
    echo "    --debug                           | Print debug output.                                                                                  "
    echo ""
    echo "The following options are passed to \`git log\` to search for suitable commits:"
    echo "  -n --max-count --skip --since --after --until --before --author --committer --grep-reflog --grep --min-parents --max-parents ARG"
    echo "  --all-match --invert-grep -i --regexp-ignore-case --basic-regexp -E --extended-regexp -F --fixed-strings -P --perl-regexp --merges --no-merges --no-min-parents --no-max-parents --first-parent --not"
    echo ""
    echo "OUTPUT_FMT is the output format of \`git show\` (See \"^PRETTY FORMATS\" in \`git show --help\`.) extended by the following placeholders:"
    echo "  %version - The version at the time of the commit."
    echo "  %tickets - All #[0-9]+ ticket numbers that appear in the commit message."
    echo ""
    echo "Current formatting: --ver \"$VERSIONFORMAT\" --fmt \"$OUTPUTFORMAT\""
    echo ""
    echo "Examples:"
    echo "  # Show version information for every commit (under HEAD) for the ticket #12345:"
    echo "  $ git $SUBCOMMAND_NAME 12345"
    echo "      1.19.0 @ b368c6128 john #12345"
    echo "      1.19.0 @ 5aedfd545 john #12345"
    echo "      1.19.0 @ b7ef59fc1 marc #12345"
    echo "      1.19.0 @ ac809141a john #12345"
    echo "      1.19.0 @ 3b31884e4 john #12345"
    echo "      1.19.0 @ 37650a34b john #12345"
    echo "  "
    echo "  # Show only commits directly in origin/main and 8dbd2ff2c additionally:"
    echo "  $ git $SUBCOMMAND_NAME --first-parent --merged origin/main '#12345' 8dbd2ff2c"
    echo "      1.19.0 @ 8dbd2ff2c marc #23456 #34567"
    echo "      1.19.0 @ b368c6128 john #12345"
    echo "      1.19.0 @ 5aedfd545 john #12345"
    echo "      1.19.0 @ b7ef59fc1 marc #12345"
    echo "  "
    echo "  # For all local branches:"
    echo "  $ git $SUBCOMMAND_NAME --first-parent --branches t12345 8dbd2ff2c"
    echo "      1.19.0 @ 8dbd2ff2c marc #23456 #34567"
    echo "     1.18.12 @ 98a102416 john #12345"
    echo "      1.19.0 @ b368c6128 john #12345"
    echo "     1.18.12 @ f8a39c3ae john #12345"
    echo "      1.19.0 @ 5aedfd545 john #12345"
    echo "     1.18.12 @ 29e8a5fa8 john #12345"
    echo "     1.18.12 @ 9fb3d5293 john #12345"
    echo "     1.18.12 @ d54b67143 john #12345"
    echo "      1.19.0 @ b7ef59fc1 marc #12345"
    echo "  "
    echo "  # Choose a custom output format:"
    echo "  $ git $SUBCOMMAND_NAME --version-format= --format='%H %s for %version' 98a102416 b368c6128"
    echo "  98a102416a2a37d569f4d78620c9e59c694a844b fix: performance #12345 for 1.18.12"
    echo "  b368c6128d776e67267d729e51ffdadf802db6da fix: performance #12345 for 1.19.0"
    echo ""
}

declare -a GITCOMMITISHS=()
declare -a GITSEARCHARGS=()
declare -i DODEBUG="0"
VERSIONFORMAT="%10s"
OUTPUTFORMAT="%version @ %Cgreen%h%Creset %cl %tickets"

getoptstr="$(getopt -n "$0" -o "hc:A:m:abs:t:n:iEFPx:V:f:" -l "help,commit,ancestor:,merged:,all,branches,search:,ticket:,max-count:,skip:,since:,after:,until:,before:,author:,committer:,grep-reflog:,grep:,min-parents:,max-parents:,merges,no-merges,no-min-parents,no-max-parents,first-parent,not,argument:,version-format:,fmt:,format:,debug" -- "$@")" || exit
eval set -- "$getoptstr"
unset getoptstr
while test "$#" -gt 0 ;do
    case "$1" in
        "-h"|"--help") USAGE "$1" ;exit 0 ;;
        "-c"|"--commit") shift ;GITCOMMITISHS+=( "$1" ) ;;
        "-A"|"--ancestor"|"-m"|"--merged") shift ;GITSEARCHARGS+=( "$1" ) ;;
        "-a"|"--all") GITSEARCHARGS+=( "--all" ) ;;
        "-b"|"--branches") GITSEARCHARGS+=( "--branches" ) ;;
        "-s"|"--search") shift ;GITSEARCHARGS+=( "--grep" "$1" ) ;;
        "-t"|"--ticket") shift ;GITSEARCHARGS+=( "--grep" "#${1#[#t]}\b" ) ;;
        "-n"|"--max-count"|"--skip"|"--since"|"--after"|"--until"|"--before"|"--author"|"--committer"|"--grep-reflog"|"--grep"|"--min-parents"|"--max-parents") GITSEARCHARGS+=( "$1" "$2" ) ;shift ;;
        "--all-match"|"--invert-grep"|"-i"|"--regexp-ignore-case"|"--basic-regexp"|"-E"|"--extended-regexp"|"-F"|"--fixed-strings"|"-P"|"--perl-regexp"|"--merges"|"--no-merges"|"--no-min-parents"|"--no-max-parents"|"--first-parent"|"--not") GITSEARCHARGS+=( "$1" ) ;;
        "-x"|"--argument") shift ;GITSEARCHARGS+=( "$1" ) ;;
        "-V"|"--version-format") shift ;VERSIONFORMAT="${1:-"%s"}" ;;
        "-f"|"--fmt"|"--format") shift ;OUTPUTFORMAT="$1" ;;
        "--debug") DODEBUG="1" ;;
        "--") shift ;break ;;
        *) { echo -n "Unhandled argument at:" ;printf ' "%s"' "$@" ;echo ; } >&2 ;exit 1 ;;
    esac
    shift
done
for arg in "$@" ;do
    if [[ "$arg" =~ ^[#t]?([0-9]+)$ ]] ;then
        test "$DODEBUG" -gt 0 && echo "BASH_REMATCH[1]=${BASH_REMATCH[1]}" >&2
        GITSEARCHARGS+=( "--grep" "#${BASH_REMATCH[1]}\b" )
    else
        GITCOMMITISHS+=( "$arg" )
    fi
done
if test "${#GITCOMMITISHS[@]}" -eq 0 -a "${#GITSEARCHARGS[@]}" -eq 0 ;then
    GITCOMMITISHS+=( "HEAD" )
fi

if test "$DODEBUG" -gt 0 ;then
    {
        echo -n "GITCOMMITISHS=("
        printf ' "%s"' "${GITCOMMITISHS[@]}"
        echo " )"
        echo -n "GITSEARCHARGS=("
        printf ' "%s"' "${GITSEARCHARGS[@]}"
        echo " )"
    } >&2
fi
if test "${#GITSEARCHARGS[@]}" -gt 0 ;then
    set -f
    IFS=$'\n'
    GITCOMMITISHS+=( $(git log "${GITSEARCHARGS[@]}" --format='%H' --no-patch) )
    unset IFS
    set +f
fi

test "$DODEBUG" -gt 0 && { echo -n "GITCOMMITISHS=(" ;printf ' "%s"' "${GITCOMMITISHS[@]}" ;echo " )" ; } >&2

for arg in "${GITCOMMITISHS[@]}" ;do
    # TODO You probably need to change this expression to find the application's version in your repository.
    version="$(git --no-pager show "$arg":frontend/package.json |sed -Ene 's/^\s*['\''"]?version['\''"]?\s*:\s*['\''"]?([^'\''"]*)['\''"]?\s*,\s*$/\1/p')"
    tickets="$(git --no-pager show --format=%B --no-patch "$arg" |grep -Eo '#[0-9]+')"
    tickets="${tickets//$'\n'/ }"
    test "$DODEBUG" -gt 0 && echo "gitcommitish=\"$arg\" version=\"$version\" tickets=\"$tickets\"" >&2
    printf -v version "$VERSIONFORMAT" "$version" || exit
    format="${OUTPUTFORMAT//"%version"/"$version"}"
    format="${format//"%tickets"/"$tickets"}"
    git --no-pager show --format="$format" --no-patch "$arg"
done

