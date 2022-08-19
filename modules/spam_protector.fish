#!/bin/fish

set -g __module_name "Spam protection module (spam_protector.fish)"
set -g __module_description "Mainly protecting RM6785 groups from scam bot"
set -g __module_version 69
set -g __module_functions usdt msg_bl
set -g __module_help_message "Protects most RM6785 community groups from usdt bots\. Available commands:
None\.
"

set -g rm6785_photography_id -1001267207006
set -g sus_match \
    usdt \
    300 \
    "private message" \
    "private chat" \
    crypto \
    bitcoin \
    forex \
    "join me" \
    "to chat"

set -g msg_blocklist \
    crypto \
    bitcoin \
    forex \
    "t\.me/joinchat/" \
    drеаmswhales \
    "meet you all" \
    "very happy" \
    "new comer" \
    invest \
    "t.me/\+" \
    ᴛʀᴀᴅɪɴɢ \
    ɪɴᴠᴇsᴛ \
    trading \
    trade \
    usdt \
    btc

function usdt --on-event modules_trigger
    if test "$ret_chat_id" != "$rm6785_photography_id"
        pr_debug spam_protector "Not Photography group, returning"
        return
    end

    pr_info spam_protector "Checking user $msgger"
    pr_debug spam_protector "First name: $ret_first_name"
    pr_debug spam_protector "Last name: $ret_last_name"

    set -l name "$ret_first_name $ret_last_name"
    pr_debug spam_protector "Combined name: $name"
    for match in $sus_match
        if string match -qei $match $name
            pr_info spam_protector "Name matched, banning"
            tg --delmsg $ret_chat_id $ret_msg_id
            tg --ban $ret_chat_id $msgger
            tg --sendmsg $ret_chat_id "Banned $msgger ($ret_first_name), match in name: $match"
            pr_info spam_protector "User $msgger banned"
            break
        end
    end
end

set -g not_admin_groups
function msg_bl --on-event modules_trigger
    if contains -- $ret_chat_id $not_admin_groups
        pr_info spam_protector "Found group '$ret_chat_id' in blacklist, skipping"
        pr_warn spam_protector "Reload this module to clear out blacklist"
        return
    end

    if not is_admin $ret_chat_id $bot_id
        pr_info spam_protector "Not admin in group '$ret_chat_id'"
        pr_debug spam_protector "Adding group '$ret_chat_id' to blacklist"
        set -a not_admin_groups $ret_chat_id
        return
    end

    for match in $msg_blocklist
        pr_debug spam_protector "Match word : $match"
        pr_debug spam_protector "User's text: $ret_msg_text"
        if string match -qei $match $ret_msg_text
            pr_info spam_protector "Message from user '$msgger' contains blacklisted word: '$match', muting"
            if not is_admin $ret_chat_id $msgger
                tg --mute $ret_chat_id $msgger
                tg --sendmarkdownv2msg $ret_chat_id "Muted user [$ret_first_name](tg://user?id=$msgger)"
                pr_debug spam_protector "Muted user '$msgger'"
            else
                pr_warn spam_protector "Cannot mute user '$msgger': user is admin"
            end
            break
        end
    end
end
