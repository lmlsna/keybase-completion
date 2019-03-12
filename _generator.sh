#!/bin/bash
#
# Keybase bash-completion generator script
#
# This script parses the output of the `keybase help` command and its various
# subcommands to produce an updated, exhaustive, static list for each.
#
# It then generates a precomputed static bash-completion script based on the
# one from https://github.com/tiersch/keybase-completion.
#
# Writes the latest static autocomplete file to the path specified in the
# OUTPUT_FILE variable below.
#
OUTPUT_FILE="/usr/share/bash-completion/completions/keybase"

# Parses keybase help function to get a list of commands up to 2 levels deep
# `keybase help command` will give list of subcommands but it appears that
# `keybase help command subcommand` ignores subcommand, so this is as deep as it
# goes I think.
#
function _keybase_commands {
    # raw help text # grep all after commands # stop at blank line  # remove: lead ws, after tab. break on , # remove COMMANDS, blanks    # sort # one line
    keybase help $1 | grep 'COMMANDS:' -A 999 | grep -E '^$' -B 999 | sed 's/^[ ]\+//g;s/\t.*$//g;s/, /\n/g' | grep -Ev '(COMMANDS\:|^$)' | sort | xargs
}

cat > $OUTPUT_FILE << __KB__
#!/usr/bin/env bash

function _keybase() {
    local cur prev prevs lprev
    COMPREPLY=()
    cur="\${COMP_WORDS[COMP_CWORD]}"
    prev="\${COMP_WORDS[COMP_CWORD-1]}"
    prevs=("\${COMP_WORDS[@]:1:\$COMP_CWORD-1}")
    lprev=\${#prevs[@]}

    # Will try to keep args and their cases sorted alphabetically -jhazelwo
    local commands="$( _keybase_commands )"

    if [[ \$lprev -eq 0 ]]; then
        COMPREPLY+=(\$(compgen -W "\${commands}" -- \${cur}))
    else
        case "\${prevs[0]}" in
__KB__

for c in $( _keybase_commands ); do
  if [ $( _keybase_commands $c | wc -w ) -ge 1 ]; then
     cat >> $OUTPUT_FILE << __KB__
            $c)
                if [[ \$lprev -eq 1 ]]; then
                    commands="$( _keybase_commands $c)"
                    COMPREPLY+=(\$(compgen -W "\${commands}" -- \${cur}))
                    return 0
                fi
                ;;
__KB__

  else
    echo -e "\t\t\t$c)\n\t\t\t\treturn 0\n\t\t\t\t;;\n" >> $OUTPUT_FILE
  fi
done

echo -e "\t\tesac\n\tfi\n}\ncomplete -F _keybase keybase\n\n# vim: syntax=sh sts=4 ts=4 sw=4 sr et" >> $OUTPUT_FILE
