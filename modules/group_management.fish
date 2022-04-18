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
        case '.purge*'
            tg --replymsg $ret_chat_id $ret_msg_id Verifying

            verify
            or return

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
                if test (jobs | count) -ge 100 # Limit resource usage
                    # wait # We're not gonna use this, since it will wait for all jobs
                    while test (jobs | count) -gt 50
                        # Do nothing
                    end
                end
            end
            wait
            set -l purge_end_time (date +%s.%N)
            set -l purge_diff_time (math $purge_end_time - $purge_start_time)

            empty .purge $ret_msg_text
            and tg --sendmsg $ret_chat_id "Purge completed. Purged $(math $sent_msg_id - $ret_replied_msg_id) messages in $(round $purge_diff_time 3)"
            or tg --sendmsg $ret_chat_id "Purge completed. Purged $(math $sent_msg_id - $ret_replied_msg_id) messages in $(round $purge_diff_time 3)
Reason: $(string replace -r '^.purge ' '' $ret_msg_text)"

        case '.pin*'
            verify
            or return

            tg --pinmsg $ret_chat_id $ret_replied_msg_id

            empty .pin $ret_msg_text
            and tg --editmsg $ret_chat_id $sent_msg_id "Message pinned."
            or tg --editmsg $ret_chat_id $sent_msg_id "Message pinned.
Reason: $(string replace -r '^.pin ' '' $ret_msg_text)"

        case '.unpin*'
            verify
            or return

            tg --unpinmsg $ret_chat_id $ret_replied_msg_id

            empty .unpin $ret_msg_text
            and tg --editmsg $ret_chat_id $sent_msg_id "Message unpinned."
            or tg --editmsg $ret_chat_id $sent_msg_id "Message unpinned.
Reason: $(string replace -r '^.unpin ' '' $ret_msg_text)"

        case '.ban*'
            verify
            or return

            tg --ban $ret_chat_id $ret_replied_msgger_id

            empty .ban $ret_msg_text
            and tg --editmsg $ret_chat_id $sent_msg_id "Banned that user."
            or tg --editmsg $ret_chat_id $sent_msg_id "Banned that user.
Reason: $(string replace -r '^.ban ' '' $ret_msg_text)"

        case '.unban*'
            verify
            or return

            tg --unban $ret_chat_id $ret_replied_msgger_id

            empty .unban $ret_msg_text
            and tg --editmsg $ret_chat_id $sent_msg_id "Unbanned that user."
            or tg --editmsg $ret_chat_id $sent_msg_id "Unbanned that user.
Reason: $(string replace -r '^.unban ' '' $ret_msg_text)"

        case '.kick*'
            verify
            or return

            tg --ban $ret_chat_id $ret_replied_msgger_id
            tg --unban $ret_chat_id $ret_replied_msgger_id

            empty .kick $ret_msg_text
            and tg --editmsg $ret_chat_id $sent_msg_id "Kicked that user."
            or tg --editmsg $ret_chat_id $sent_msg_id "Kicked that user.
ReasonL $(string replace -r '^.kick ' '' $ret_msg_text)"

        case '.mute*'
            verify
            or return

            tg --mute $ret_chat_id $ret_replied_msgger_id

            empty .mute $ret_msg_text
            and tg --editmsg $ret_chat_id $sent_msg_id "Muted that user."
            or tg --editmsg $ret_chat_id $sent_msg_id "Muted that user.
Reason: $(string replace -r '^.mute ' '' $ret_msg_text)"

        case '.unmute*'
            verify
            or return

            tg --unmute $ret_chat_id $ret_replied_msgger_id

            empty .unmute $ret_msg_text
            and tg --editmsg $ret_chat_id $sent_msg_id "User unmuted."
            or tg --editmsg $ret_chat_id $sent_msg_id "User unmuted.
Reason: $(string replace -r '^.unmute ' '' $ret_msg_text)"

        case '.promote*'
            verify
            or return

            tg --promote $ret_chat_id $ret_replied_msgger_id

            empty .promote $ret_msg_text
            and tg --editmsg $ret_chat_id $sent_msg_id "Promoted that user."
            or tg --editmsg $ret_chat_id $sent_msg_id "Promoted that user.
Reason: $(string replace -r '^.promote ' '' $ret_msg_text)"

        case '.demote*'
            verify
            or return

            tg --demote $ret_chat_id $ret_replied_msgger_id

            empty .demote $ret_msg_text
            and tg --editmsg $ret_chat_id $sent_msg_id "Demoted that user."
            or tg --editmsg $ret_chat_id $sent_msg_id "Demoted that user.
Reason: $(string replace -r '^.demote ' '' $ret_msg_text)"
    end
end

function verify
    tg --replymsg $ret_chat_id $ret_msg_id Verifying
    test $ret_replied_msg_id != null
    or tg --editmsg $ret_chat_id $sent_msg_id "Reply to a message please" && return 1

    if not is_admin $ret_chat_id $msgger $this_bot_id
        tg --editmsg $ret_chat_id $sent_msg_id "Verification failed, either I or you (or both) is not an admin"
        return 1
    end

    return 0
end

function empty
    # Args:
    # 1 - What to replace; e.g .kick
    # 2 - The string to check
    test (count $argv) -eq 2
    or pr_error group_management "Function empty: Incorrect number of arguments passed." && return 2

    test -z (string replace -r "^$argv[1]" '' $argv[2])
    and return 0
    or return 1
end

# Init
set -g this_bot_id (curl -s $API/getMe | jq .result.id)
