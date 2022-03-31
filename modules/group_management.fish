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
            set -l purge_start_time (date +%s.%N)
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
            set -l purge_end_time (date +%s.%N)
            set -l purge_diff_time (math $purge_end_time - $purge_start_time)
            tg --sendmsg $ret_chat_id "Purge completed. Took $(round $purge_diff_time 3)"
        case '.pin'
            verify
            or return

            tg --pinmsg $ret_chat_id $ret_replied_msg_id
            tg --editmsg $ret_chat_id $sent_msg_id "Message pinned."

        case '.unpin'
            verify
            or return

            tg --unpinmsg $ret_chat_id $ret_replied_msg_id
            tg --editmsg $ret_chat_id $sent_msg_id "Message unpinned."

        case '.ban'
            verify
            or return

            tg --ban $ret_chat_id $ret_replied_msgger_id
            tg --editmsg $ret_chat_id $sent_msg_id "Banned that user."

        case '.unban'
            verify
            or return

            tg --unban $ret_chat_id $ret_replied_msgger_id
            tg --editmsg $ret_chat_id $sent_msg_id "Unbanned that user."

        case '.kick'
            verify
            or return

            tg --ban $ret_chat_id $ret_replied_msgger_id
            tg --unban $ret_chat_id $ret_replied_msgger_id
            tg --editmsg $ret_chat_id $sent_msg_id "Kicked that user."

        case '.mute'
            verify
            or return

            tg --mute $ret_chat_id $ret_replied_msgger_id
            tg --editmsg $ret_chat_id $sent_msg_id "Muted that user."

        case '.unmute'
            verify
            or return

            tg --unmute $ret_chat_id $ret_replied_msgger_id
            tg --editmsg $ret_chat_id $sent_msg_id "User unmuted."

        case '.promote'
            verify
            or return

            tg --promote $ret_chat_id $ret_replied_msgger_id
            tg --editmsg $ret_chat_id $sent_msg_id "Promoted that user."

        case '.demote'
            verify
            or return

            tg --demote $ret_chat_id $ret_replied_msgger_id
            tg --editmsg $ret_chat_id $sent_msg_id "Demoted that user."
    end
end

function verify
    tg --replymsg $ret_chat_id $ret_msg_id "Verifying"
    test $ret_replied_msg_id != null
    or tg --editmsg $ret_chat_id $sent_msg_id "Reply to a message please" && return 1

    is_admin $ret_chat_id $msgger
    or tg --editmsg $ret_chat_id $sent_msg_id "Error, you are not an admin" && return 1

    is_admin $ret_chat_id $this_bot_id
    or tg --editmsg $ret_chat_id $sent_msg_id "Error, I am not admin" && return 1

    return 0
end

# Init
set -g this_bot_id (curl -s $API/getMe | jq .result.id)
