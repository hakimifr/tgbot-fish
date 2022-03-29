#!/bin/fish

set -g chat_id $argv[1]
set -g msg_id $argv[2]

# Although we pass $argv[3] as 1 arguments, let's make it so it accepts
# all args if some dummy (which might be me) decides to split them later
# (though we really shouldn't lol..)
set -e argv[1 2]
set -g cmds "$argv" # Quote, prevent splitting on newline

# Source util so we can reply
source util.fish

set -g command_output "$(bash -c "$cmds")"
if test $status -ne 0
    set -g command_failed true
else
    set -g command_failed false
end

test $command_failed = true
and tg --replymsg "$chat_id" "$msg_id" "Command exited with status non-zero (failed), output:
$command_output"
or tg --replymsg "$chat_id" "$msg_id" "Command exited with status zero (success), output:
$command_output"
