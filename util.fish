#!/bin/fish

source .token.fish

if not set -q curl_out # Output of curl for tg() function
    # Discard
    set -g curl_out /dev/null
end

set API "https://api.telegram.org/bot$TOKEN"
function tg -d "Send message and more"
    switch $argv[1]
        # Sending messages
        case "--sendmsg"
            set -l result (curl -s "$API/sendMessage" -d "chat_id=$argv[2]" -d "text=$argv[3]")
            set -g sent_msg_id (echo $result | jq '.result.message_id')
        case "--sendmarkdownv2msg"
            set -l result (curl -s "$API/sendMessage" -d "chat_id=$argv[2]" -d "text=$argv[3]" -d "parse_mode=MarkdownV2")
            set -g sent_msg_id (echo $result | jq '.result.message_id')

        # Replying
        case "--replymsg"
            set -l result (curl -s "$API/sendMessage" -d "chat_id=$argv[2]" -d "reply_to_message_id=$argv[3]" -d "text=$argv[4]")
            set -g sent_msg_id (echo $result | jq '.result.message_id')
        case "--replymarkdownv2msg"
            set -l result (curl -s "$API/sendMessage" -d "chat_id=$argv[2]" -d "reply_to_message_id=$argv[3]" -d "text=$argv[4]" -d "parse_mode=MarkdownV2")
            set -g sent_msg_id (echo $result | jq '.result.message_id')

        # Editing & deleting
        case "--editmsg"
            curl -s "$API/editMessageText" -d "chat_id=$argv[2]" -d "message_id=$argv[3]" -d "text=$argv[4]" | jq -C . > $curl_out
        case "--editmarkdownv2msg"
            curl -s "$API/editMessageText" -d "chat_id=$argv[2]" -d "message_id=$argv[3]" -d "text=$argv[4]" -d "parse_mode=MarkdownV2" | jq -C . > $curl_out
        case "--delmsg"
            curl -s "$API/deleteMessage" -d "chat_id=$argv[2]" -d "message_id=$argv[3]" | jq -C . > $curl_out

        # Stickers
        case "--sendsticker"
            curl -s "$API/sendSticker" -d "chat_id=$argv[2]" -d "sticker=$argv[3]" | jq -C . > $curl_out
        case "--replysticker"
            curl -s "$API/sendSticker" -d "chat_id=$argv[2]" -d "reply_to_message_id=$argv[3]" -d "sticker=$argv[4]" | jq -C . > $curl_out

        # Forwarding
        case "--forwardmsg"
            curl -s "$API/forwardMessage" -d "from_chat_id=$argv[2]" -d "chat_id=$argv[3]" -d "message_id=$argv[4]" | jq -C . > $curl_out
        case "--cpmsg"
            curl -s "$API/copyMessage" -d "from_chat_id=$argv[2]" -d "chat_id=$argv[3]" -d "message_id=$argv[4]" | jq -C . > $curl_out

        # Chat management
        case "--pinmsg"
            curl -s "$API/pinChatMessage" -d "chat_id=$argv[2]" -d "message_id=$argv[3]" | jq -C . > $curl_out
        case "--unpinmsg"
            curl -s "$API/unpinChatMessage" -d "chat_id=$argv[2]" -d "message_id=$argv[3]" | jq -C . > $curl_out
        # TODO: Add ban, kick, etc
    end
end

function update -d "Get updates"
    set -g fetch (curl -s "$API/getUpdates" -d "offset=$update_id" -d "timeout=60" | jq '.result[]')

    if test -n "$fetch"
        set -g update_id (math $update_id + 1)
        # IDs
        set -g prev_update_id $update_id
        set -g ret_msg_id (echo "$fetch" | jq '.message.message_id')
        set -g ret_chat_id (echo "$fetch" | jq '.message.chat.id')
        set -g msgger (echo "$fetch" | jq '.message.from.id')
        set -g ret_file_id (echo "$fetch" | jq -r '.message.document.file_id')

        # Strings
        set -g ret_msg_text (echo "$fetch" | jq -r '.message.text')
        set -g first_name (echo "$fetch" | jq -r '.message.first_name')
        set -g username (echo "$fetch" | jq -r '.message.username')

        # Replies
        set -g ret_replied_msg_id (echo "$fetch" | jq '.message.reply_to_message.message_id')
        set -g ret_replied_msgger_id (echo "$fetch" | jq '.message.reply_to_message.from.id')
        set -g ret_replied_msg_text (echo "$fetch" | jq -r '.message.reply_to_message.text')
        set -g ret_replied_file_id (echo "$fetch" | jq -r '.message.reply_to_message.document.file_id')

        # Stickers
        set -g sticker_emoji (echo "$fetch" | jq -r '.message.sticker.emoji')
        set -g sticker_file_id (echo "$fetch" | jq -r '.message.sticker.file_id')
        set -g sticker_pack_name (echo "$fetch" | jq -r '.message.sticker.set_name')

        set -ge fetch
    end
end

function update_init -d "Get initial update ID"
    set -g update_id (curl -s $API/getUpdates -d offset=-1 -d timeout=60 | jq '.result[].update_id')
end

function is_botowner -d "Check whether a user is botowner"
    test "$msgger" = "$bot_owner_id" && return 0
    return 1
end

function err_not_botowner -d "Reply with a message stating they aren't the bot owner"
    tg --replymsg "$ret_chat_id" "$ret_msg_id" "You are not allowed to use this command."
end

function __pr_gen
    set -l date (date +%H:%M:%S)
    echo -e "$date - [$argv[1]] - $argv[2]"
end

function pr_info
    set_color green; __pr_gen $argv[1] $argv[2]; set_color normal
end

function pr_warn
    set_color yellow; __pr_gen $argv[1] $argv[2]; set_color normal
end

function pr_error
    set_color red; __pr_gen $argv[1] $argv[2]; set_color normal
end

function pr_debug
    set_color magenta; __pr_gen $argv[1] $argv[2]; set_color normal
end
