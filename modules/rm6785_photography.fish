#!/bin/fish

set -g __module_name "RM6785 Photography (rm6785_photography.fish)"
set -g __module_description "Protects @RM6785Photography from usdt scam bot"
set -g __module_version 69
set -g __module_functions usdt
set -g __module_help_message "Protects @RM6785Photography from usdt bots\. Available commands:
None\.
"

set -g rm6785_photography_id -1001267207006
set -g sus_match usdt \
    300 \
    "private message" \
    crypto \
    bitcoin \
    forex \
    "join me" \
    "to chat"

function usdt --on-event modules_trigger
    if test "$ret_chat_id" != "$rm6785_photography_id"
        pr_debug rm6785_photography "Not Photography group, returning"
        return
    end

    pr_info rm6785_photography "Checking user $msgger"
    pr_debug rm6785_photography "First name: $ret_first_name"
    pr_debug rm6785_photography "Last name: $ret_last_name"

    set -l name "$ret_first_name $ret_last_name"
    pr_debug rm6785_photography "Combined name: $name"
    for match in $sus_match
        if string match -qri $match $name
            pr_info rm6785_photography "Name matched, banning"
            tg --delmsg $ret_chat_id $ret_msg_id
            tg --ban $ret_chat_id $msgger
            tg --sendmsg $ret_chat_id "Banned $msgger ($ret_first_name), match in name: $match"
            pr_info rm6785_photography "User $msgger banned"
            break
        end
    end
end
