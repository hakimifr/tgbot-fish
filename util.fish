#!/bin/fish

source .token.fish

if not set -q curl_out # Output of curl for tg() function
    # Discard
    set -g curl_out /dev/null
end

set -g BOT_HOME $PWD

set API https://api.telegram.org/bot$TOKEN
function tg -d "Send message and more"
    switch $argv[1]
        # Sending messages
        case --sendmsg
            set -l result (curl -s $API/sendMessage -d chat_id=$argv[2] -d text=$argv[3] -d disable_web_page_preview=true)
            set -g sent_msg_id (echo $result | jq '.result.message_id')
        case --sendmarkdownv2msg
            set -l result (curl -s $API/sendMessage -d chat_id=$argv[2] -d text=$argv[3] -d parse_mode=MarkdownV2 -d disable_web_page_preview=true)
            set -g sent_msg_id (echo $result | jq '.result.message_id')

            # Replying
        case --replymsg
            set -l result (curl -s $API/sendMessage -d chat_id=$argv[2] -d reply_to_message_id=$argv[3] -d text=$argv[4] -d disable_web_page_preview=true)
            set -g sent_msg_id (echo $result | jq '.result.message_id')
        case --replymarkdownv2msg
            set -l result (curl -s $API/sendMessage -d chat_id=$argv[2] -d reply_to_message_id=$argv[3] -d text=$argv[4] -d parse_mode=MarkdownV2 -d disable_web_page_preview=true)
            set -g sent_msg_id (echo $result | jq '.result.message_id')

            # Editing & deleting
        case --editmsg
            curl -s $API/editMessageText -d chat_id=$argv[2] -d message_id=$argv[3] -d text=$argv[4] -d disable_web_page_preview=true | jq -C . >$curl_out
        case --editmarkdownv2msg
            curl -s $API/editMessageText -d chat_id=$argv[2] -d message_id=$argv[3] -d text=$argv[4] -d parse_mode=MarkdownV2 -d disable_web_page_preview=true | jq -C . >$curl_out
        case --editcaption
            curl -s $API/editMessageCaption -d chat_id=$argv[2] -d message_id=$argv[3] -d text=$argv[4] | jq -C . >$curl_out
        case --editcaptionmarkdownv2
            curl -s $API/editMessageCaption -d chat_id=$argv[2] -d message_id=$argv[3] -d text=$argv[4] -d parse_mode=MarkdownV2 jq -C . >$curl_out
        case --delmsg
            curl -s $API/deleteMessage -d chat_id=$argv[2] -d message_id=$argv[3] | jq -C . >$curl_out

            # Stickers
        case --sendsticker
            curl -s $API/sendSticker -d chat_id=$argv[2] -d sticker=$argv[3] | jq -C . >$curl_out
        case --replysticker
            curl -s $API/sendSticker -d chat_id=$argv[2] -d reply_to_message_id=$argv[3] -d sticker=$argv[4] | jq -C . >$curl_out

            # Forwarding
        case --forwardmsg
            curl -s $API/forwardMessage -d from_chat_id=$argv[2] -d chat_id=$argv[3] -d message_id=$argv[4] | jq -C . >$curl_out
        case --cpmsg
            curl -s $API/copyMessage -d from_chat_id=$argv[2] -d chat_id=$argv[3] -d message_id=$argv[4] | jq -C . >$curl_out

            # Chat management
        case --pinmsg
            curl -s $API/pinChatMessage -d chat_id=$argv[2] -d message_id=$argv[3] | jq -C . >$curl_out
        case --unpinmsg
            curl -s $API/unpinChatMessage -d chat_id=$argv[2] -d message_id=$argv[3] | jq -C . >$curl_out
        case --ban
            curl -s $API/banChatMember -d chat_id=$argv[2] -d user_id=$argv[3] | jq -C . >$curl_out
        case --unban
            curl -s $API/unbanChatMember -d chat_id=$argv[2] -d user_id=$argv[3] -d only_if_banned=true | jq -C . >$curl_out
        case --promote
            curl -s $API/promoteChatMember -d chat_id=$argv[2] -d user_id=$argv[3] \
                -d can_manage_chat=true \
                -d can_post_messages=true \
                -d can_edit_messages=true \
                -d can_delete_messages=true \
                -d can_manage_voice_chats=true \
                -d can_restrict_members=true \
                -d can_change_info=true \
                -d can_invite_users=true \
                -d can_pin_messages=true \
                -d is_anonymous=false \
                -d can_promote_members=false | jq -C . >$curl_out
        case --demote
            curl -s $API/promoteChatMember -d chat_id=$argv[2] -d user_id=$argv[3] \
                -d can_manage_chat=false \
                -d can_post_messages=false \
                -d can_edit_messages=false \
                -d can_delete_messages=false \
                -d can_manage_voice_chats=false \
                -d can_restrict_members=false \
                -d can_change_info=false \
                -d can_invite_users=false \
                -d can_pin_messages=false \
                -d is_anonymous=false \
                -d can_promote_members=false | jq -C . >$curl_out
        case --mute
            curl -s $API/restrictChatMember -d chat_id=$argv[2] -d user_id=$argv[3] -d \
                permissions='{"can_send_messages": false}' | jq -C . >$curl_out
        case --unmute
            curl -s $API/restrictChatMember -d chat_id=$argv[2] -d user_id=$argv[3] -d \
                permissions'={
                    "can_send_messages": true,
                    "can_send_media_messages": true,
                    "can_send_polls": true,
                    "can_send_other_messages": true,
                    "can_add_web_page_previews": true,
                    "can_change_info": true,
                    "can_invite_users": true,
                    "can_pin_messages": true
                }' | jq -C . >$curl_out
    end
end

function update -d "Get updates"
    set -g fetch "$(curl -s $API/getUpdates -d offset=$update_id -d timeout=60 | jq '.result[]')" # Quote to prevent newline splitting

    if test -n "$fetch"
        set -g update_id (math $update_id + 1)
        # IDs
        set -g prev_update_id $update_id
        set -g ret_msg_id (echo $fetch | jq '.message.message_id')
        set -g ret_chat_id (echo $fetch | jq '.message.chat.id')
        set -g msgger (echo $fetch | jq '.message.from.id')
        set -g ret_file_id (echo $fetch | jq -r '.message.document.file_id')
        set -g ret_file_unique_id (echo $fetch | jq -r '.message.document.file_unique_id')

        # Names
        set -g ret_first_name (echo $fetch | jq -r '.message.from.first_name')
        set -g ret_last_name (echo $fetch | jq -r '.message.from.last_name')
        set -g ret_username (echo $fetch | jq -r '.message.from.username')
        set -g ret_replied_first_name (echo $fetch | jq -r '.message.reply_to_message.from.first_name')
        set -g ret_replied_last_name (echo $fetch | jq -r '.message.reply_to_message.from.last_name')
        set -g ret_replied_username (echo $fetch | jq -r '.message.reply_to_message.from.username')

        # Strings
        set -g ret_msg_text (echo $fetch | jq -r '.message.text')

        # Replies
        set -g ret_replied_msg_id (echo $fetch | jq '.message.reply_to_message.message_id')
        set -g ret_replied_msgger_id (echo $fetch | jq '.message.reply_to_message.from.id')
        set -g ret_replied_msg_text (echo $fetch | jq -r '.message.reply_to_message.text')
        set -g ret_replied_file_id (echo $fetch | jq -r '.message.reply_to_message.document.file_id')
        set -g ret_replied_file_unique_id (echo $fetch | jq -r '.message.reply_to_message.document.file_unique_id')

        # Stickers
        set -g sticker_emoji (echo $fetch | jq -r '.message.sticker.emoji')
        set -g sticker_file_id (echo $fetch | jq -r '.message.sticker.file_id')
        set -g sticker_pack_name (echo $fetch | jq -r '.message.sticker.set_name')

        set -g global_fetch $fetch # For use by modules, etc
        set -ge fetch


        set -g ret_msg_id $ret_msg_id[1]
        set -g ret_chat_id $ret_chat_id[1]
        set -g msgger $msgger[1]
        set -g ret_file_id $ret_file_id[1]
        set -g ret_file_unique_id $ret_file_unique_id[1]

        set -g ret_first_name $ret_first_name[1]
        set -g ret_last_name $ret_last_name[1]
        set -g ret_username $ret_username[1]
        set -g ret_replied_first_name $ret_replied_first_name[1]
        set -g ret_replied_last_name $ret_replied_last_name[1]
        set -g ret_replied_username $ret_replied_username[1]

        set -g ret_msg_text $ret_msg_text[1]

        set -g ret_replied_msg_id $ret_replied_msg_id[1]
        set -g ret_replied_msgger_id $ret_replied_msgger_id[1]
        set -g ret_replied_msg_text $ret_replied_msg_text[1]
        set -g ret_replied_file_id $ret_replied_file_id[1]
        set -g ret_replied_file_unique_id $ret_replied_file_unique_id[1]

        set -g sticker_emoji $sticker_emoji[1]
        set -g sticker_file_id $sticker_file_id[1]
        set -g sticker_pack_name $sticker_pack_name[1]
    end
end

function update_init -d "Get initial update ID"
    while test -z "$update_id"
        set -g update_id (curl -s $API/getUpdates -d offset=-1 -d timeout=60 | jq '.result[].update_id')
    end
    pr_debug util "update init done. ID: $update_id"
end

function is_botowner -d "Check whether a user is botowner"
    test "$msgger" = "$bot_owner_id" && return 0
    return 1
end

function err_not_botowner -d "Reply with a message stating they aren't the bot owner"
    tg --replymsg "$ret_chat_id" "$ret_msg_id" "You are not allowed to use this command."
end

function is_admin
    test (count $argv) -ge 2
    or return 2

    set -l chat_id $argv[1]
    set -l user_id $argv[2..]
    set -l everyone_is_admin true
    pr_debug util "is_admin: Given chat id: $chat_id"
    pr_debug util "is_admin: Given user id: $user_id"

    set -l chat_admins (curl -s $API/getChatAdministrators -d chat_id=$chat_id | jq .result[].user.id)

    for user in $user_id
        if contains -- $user $chat_admins
            pr_debug util "is_admin: User $user is admin"
        else
            pr_debug util "is_admin: User $user is not admin"
            set everyone_is_admin false
        end
    end

    if test "$everyone_is_admin" = true
        pr_debug "is_admin: Everyone is admin, returning 0"
        return 0
    else
        pr_debug "is_admin: Not everyone is admin, returning 1"
        return 1
    end
end

function __pr_gen
    test -d logs
    or mkdir logs

    set -l date (date +%H:%M:%S)
    echo -e "$date - ($argv[1]) - [$argv[2]] - $argv[3]"
    echo -e "$date - ($argv[1]) - [$argv[2]] - $argv[3]" >>logs/(string lower $argv[1]).log
end

function pr_info
    set_color green
    __pr_gen INFO $argv[1] $argv[2]
    set_color normal
end

function pr_warn
    set_color yellow
    __pr_gen WARN $argv[1] $argv[2]
    set_color normal
end

function pr_error
    set_color red
    __pr_gen ERROR $argv[1] $argv[2]
    set_color normal
end

function pr_debug
    set_color magenta
    __pr_gen DEBUG $argv[1] $argv[2]
    set_color normal
end
