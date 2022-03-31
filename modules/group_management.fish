#!/bin/fish

set -g __module_name "Group Management"
set -g __module_description "Purges, ban, etc"
set -g __module_version 1
set -g __module_functions purge ban kick mute
set -g __module_help_message "\
`.purge` \-\> Purge from the replied message\.
`.mute` \-\> Mute the replied user\.
`.ban` \-\> Ban the replied user\.
`.kick` \-\> Kick the replied user\.
"

function purge --on-event modules_trigger
    switch $ret_lowered_msg_text
        case '.purge'
            tg --replymsg $ret_chat_id $ret_msg_id Verifying

            is_admin $ret_chat_id $msgger
            or tg --editmsg $ret_chat_id $sent_msg_id "Error, you are not an admin." && return
            is_admin $ret_chat_id $this_bot_id
            or tg --editmsg $ret_chat_id $sent_msg_id "Error, I am not an admin." && return

            test $ret_replied_msg_id != null
            or tg --editmsg $ret_chat_id $sent_msg_id "Reply to a message please" && return

            tg --editmsg $ret_chat_id $sent_msg_id Purging
            for msg in (seq $ret_replied_msg_id $sent_msg_id)
                fish -c "
                    set -g bot_owner_id -1001767564202
                    source util.fish;
                    tg --delmsg $ret_chat_id $msg
                " &
                #   ^^ that set -g bot_owner_id is due to my if condition in .token.fish, you don't need it
                # tg --delmsg $ret_chat_id $msg
            end
            wait
            tg --sendmsg $ret_chat_id "Purge completed."
    end
end

# Init
set -g this_bot_id (curl -s $API/getMe | jq .result.id)


## Chore
# - ban
# - mute
# - kick
